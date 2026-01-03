# frozen_string_literal: true

require 'temporary_tables'
require 'rails_helper'
require 'spec_helper'

require_dependency Rails.root / 'lib' / 'dual_writes'

describe DualWrites do
  around do |example|
    original_adapter = ActiveJob::Base.queue_adapter
    ActiveJob::Base.queue_adapter = :test
    example.run
  ensure
    ActiveJob::Base.queue_adapter = original_adapter
  end

  describe DualWrites::Model do
    temporary_table :dual_write_records do |t|
      t.uuid :account_id
      t.string :name
      t.text :data
      t.timestamps
    end

    temporary_model :dual_write_record do
      include DualWrites::Model

      dual_writes replicates_to: %i[clickhouse]
    end

    let(:model) { DualWriteRecord }

    describe '.dual_writes' do
      it 'should configure dual writes' do
        expect(model.dual_writes_config).to eq(
          replicates_to: [:clickhouse],
          async: true,
          strategy: :standard,
          resolve_with: nil,
        )
      end

      it 'should raise error for empty replicates_to' do
        expect {
          Class.new(ApplicationRecord) do
            include DualWrites::Model

            dual_writes replicates_to: []
          end
        }.to raise_error(DualWrites::ConfigurationError, /cannot be empty/)
      end

      it 'should raise error for invalid replicates_to' do
        expect {
          Class.new(ApplicationRecord) do
            include DualWrites::Model

            dual_writes replicates_to: ['clickhouse']
          end
        }.to raise_error(DualWrites::ConfigurationError, /must be an array of symbols/)
      end
    end

    describe 'after_create_commit' do
      it 'should enqueue replication job on create' do
        expect {
          model.create!(name: 'test', data: 'hello')
        }.to have_enqueued_job(DualWrites::ReplicationJob).with(
          operation: 'create',
          class_name: 'DualWriteRecord',
          primary_key: an_instance_of(Integer),
          attributes: hash_including('name' => 'test', 'data' => 'hello'),
          shard: 'clickhouse',
        )
      end
    end

    describe 'after_update_commit' do
      it 'should enqueue replication job on update' do
        record = model.create!(name: 'test', data: 'hello')

        expect {
          record.update!(name: 'updated')
        }.to have_enqueued_job(DualWrites::ReplicationJob).with(
          operation: 'update',
          class_name: 'DualWriteRecord',
          primary_key: record.id,
          attributes: hash_including('name' => 'updated'),
          shard: 'clickhouse',
        )
      end
    end

    describe 'after_destroy_commit' do
      it 'should enqueue replication job on destroy' do
        record = model.create!(name: 'test', data: 'hello')
        record_id = record.id

        expect {
          record.destroy!
        }.to have_enqueued_job(DualWrites::ReplicationJob).with(
          operation: 'destroy',
          class_name: 'DualWriteRecord',
          primary_key: record_id,
          attributes: an_instance_of(Hash),
          shard: 'clickhouse',
        )
      end
    end

    describe '.without_dual_writes' do
      it 'should disable dual writes within block' do
        expect {
          model.without_dual_writes do
            model.create!(name: 'test', data: 'hello')
          end
        }.not_to have_enqueued_job(DualWrites::ReplicationJob)
      end

      it 'should re-enable dual writes after block' do
        model.without_dual_writes do
          model.create!(name: 'test', data: 'hello')
        end

        expect {
          model.create!(name: 'test2', data: 'world')
        }.to have_enqueued_job(DualWrites::ReplicationJob)
      end

      it 'should re-enable dual writes after exception' do
        expect {
          model.without_dual_writes do
            raise 'test error'
          end
        }.to raise_error('test error')

        expect(model.dual_writes_enabled).to eq true
      end
    end

    describe '.with_sync_dual_writes' do
      temporary_table :sync_dual_write_records do |t|
        t.string :name
        t.text :data
        t.integer :is_deleted, default: 0, null: false
        t.timestamps
      end

      temporary_model :sync_dual_write_record do
        include DualWrites::Model

        dual_writes replicates_to: %i[clickhouse], strategy: :append_only, async: true
      end

      let(:sync_model) { SyncDualWriteRecord }

      it 'should switch to sync mode within block' do
        # Verify perform_now is called (sync) instead of perform_later (async)
        expect(DualWrites::ReplicationJob).to receive(:perform_now).at_least(:once)
        expect(DualWrites::ReplicationJob).not_to receive(:perform_later)

        sync_model.with_sync_dual_writes do
          sync_model.create!(name: 'test', data: 'hello')
        end
      end

      it 'should revert to async mode after block' do
        allow(DualWrites::ReplicationJob).to receive(:perform_now)

        sync_model.with_sync_dual_writes do
          sync_model.create!(name: 'test', data: 'hello')
        end

        expect(sync_model.dual_writes_config[:async]).to eq true
      end
    end

    describe 'sync replication' do
      temporary_table :sync_replication_records do |t|
        t.string :name
        t.text :data
        t.integer :is_deleted, default: 0, null: false
        t.timestamps
      end

      temporary_model :sync_replication_record do
        include DualWrites::Model

        dual_writes replicates_to: %i[clickhouse], strategy: :append_only, async: false
      end

      let(:sync_model) { SyncReplicationRecord }

      it 'should rollback primary on replication failure' do
        allow(DualWrites::ReplicationJob).to receive(:perform_now).and_raise(
          DualWrites::ReplicationError, 'simulated replication failure'
        )

        expect {
          expect {
            sync_model.create!(name: 'test', data: 'hello')
          }.to raise_error(DualWrites::ReplicationError, /simulated replication failure/)
        }.not_to change { sync_model.count }
      end

      it 'should not enqueue jobs' do
        allow(DualWrites::ReplicationJob).to receive(:perform_now)

        expect {
          sync_model.create!(name: 'test', data: 'hello')
        }.not_to have_enqueued_job(DualWrites::ReplicationJob)
      end
    end
  end

  describe DualWrites::ReplicationJob do
    let(:job) { DualWrites::ReplicationJob.new }

    describe '#perform' do
      temporary_table :replication_test_records do |t|
        t.string :name
        t.text :data
        t.timestamps
      end

      temporary_model :unconfigured_model, table_name: :replication_test_records

      it 'should raise error for unconfigured model' do
        expect {
          job.perform(
            operation: 'create',
            class_name: 'UnconfiguredModel',
            primary_key: 999_997,
            attributes: { 'name' => 'test' },
            shard: 'clickhouse',
          )
        }.to raise_error(DualWrites::ConfigurationError, /not configured for dual writes/)
      end

      context 'with invalid operation' do
        temporary_model :invalid_op_record, table_name: :replication_test_records do
          include DualWrites::Model

          dual_writes replicates_to: %i[clickhouse]
        end

        it 'should raise error for unknown operation' do
          stub_const('InvalidOpRecord::Clickhouse', InvalidOpRecord)

          expect {
            job.perform(
              operation: 'invalid',
              class_name: 'InvalidOpRecord',
              primary_key: 999_996,
              attributes: {},
              shard: 'clickhouse',
            )
          }.to raise_error(DualWrites::ReplicationError, /unknown operation/)
        end
      end
    end

    # NOTE: resolve_with uses UPDATE/DELETE which requires a SQL database (not ClickHouse).
    # These tests use the primary model as the replica to test conflict resolution logic.
    describe '#perform with resolve_with' do
      temporary_table :resolved_records do |t|
        t.string :name
        t.text :data
        t.timestamps
      end

      temporary_model :resolved_record do
        include DualWrites::Model

        dual_writes replicates_to: %i[replica], resolve_with: :updated_at
      end

      let(:resolved_model) { ResolvedRecord }

      before do
        # Stub the replica class to use the primary model (same table/connection)
        stub_const('ResolvedRecord::Replica', resolved_model)
      end

      context 'when record does not exist' do
        it 'should insert new record' do
          record_id = 888_888
          now = Time.current
          attrs = { 'name' => 'new', 'data' => 'test', 'created_at' => now, 'updated_at' => now }

          job.perform(
            operation: 'create',
            class_name: resolved_model.name,
            primary_key: record_id,
            attributes: attrs,
            shard: 'replica',
          )

          expect(resolved_model.find_by(id: record_id).name).to eq 'new'
        end
      end

      context 'when incoming data is newer' do
        it 'should update existing record' do
          old_time = 1.hour.ago
          new_time = Time.current

          record = resolved_model.create!(name: 'old', data: 'old', updated_at: old_time)

          attrs = { 'name' => 'new', 'data' => 'new', 'created_at' => old_time, 'updated_at' => new_time }

          job.perform(
            operation: 'update',
            class_name: resolved_model.name,
            primary_key: record.id,
            attributes: attrs,
            shard: 'replica',
          )

          record.reload
          expect(record.name).to eq 'new'
          expect(record.data).to eq 'new'
        end
      end

      context 'when incoming data is older (out-of-order job)' do
        it 'should skip stale update silently' do
          old_time = 1.hour.ago
          new_time = Time.current

          record = resolved_model.create!(name: 'current', data: 'current', updated_at: new_time)

          attrs = { 'name' => 'stale', 'data' => 'stale', 'created_at' => old_time, 'updated_at' => old_time }

          job.perform(
            operation: 'update',
            class_name: resolved_model.name,
            primary_key: record.id,
            attributes: attrs,
            shard: 'replica',
          )

          record.reload
          expect(record.name).to eq 'current'
          expect(record.data).to eq 'current'
        end
      end

      context 'when destroying with newer timestamp' do
        it 'should delete the record' do
          old_time = 1.hour.ago
          record = resolved_model.create!(name: 'test', data: 'test', updated_at: old_time)
          record_id = record.id

          attrs = { 'updated_at' => Time.current }

          job.perform(
            operation: 'destroy',
            class_name: resolved_model.name,
            primary_key: record_id,
            attributes: attrs,
            shard: 'replica',
          )

          expect(resolved_model.find_by(id: record_id)).to be_nil
        end
      end

      context 'when destroying with older timestamp' do
        it 'should skip stale deletion silently' do
          new_time = Time.current
          record = resolved_model.create!(name: 'test', data: 'test', updated_at: new_time)
          record_id = record.id

          attrs = { 'updated_at' => 1.hour.ago }

          job.perform(
            operation: 'destroy',
            class_name: resolved_model.name,
            primary_key: record_id,
            attributes: attrs,
            shard: 'replica',
          )

          expect(resolved_model.find_by(id: record_id)).to be_present
        end
      end
    end

    describe '#perform with lock_version resolution' do
      temporary_table :versioned_records do |t|
        t.string :name
        t.integer :lock_version, default: 0, null: false
        t.timestamps
      end

      temporary_model :versioned_record do
        include DualWrites::Model

        dual_writes replicates_to: %i[replica], resolve_with: :lock_version
      end

      let(:versioned_model) { VersionedRecord }

      before do
        # Stub the replica class to use the primary model (same table/connection)
        stub_const('VersionedRecord::Replica', versioned_model)
      end

      it 'should apply update with higher lock_version' do
        record = versioned_model.create!(name: 'v1', lock_version: 1)

        attrs = { 'name' => 'v2', 'lock_version' => 2, 'created_at' => record.created_at, 'updated_at' => Time.current }

        job.perform(
          operation: 'update',
          class_name: versioned_model.name,
          primary_key: record.id,
          attributes: attrs,
          shard: 'replica',
        )

        record.reload
        expect(record.name).to eq 'v2'
        expect(record.lock_version).to eq 2
      end

      it 'should skip update with lower lock_version silently' do
        record = versioned_model.create!(name: 'v3', lock_version: 3)

        attrs = { 'name' => 'v1', 'lock_version' => 1, 'created_at' => record.created_at, 'updated_at' => Time.current }

        job.perform(
          operation: 'update',
          class_name: versioned_model.name,
          primary_key: record.id,
          attributes: attrs,
          shard: 'replica',
        )

        record.reload
        expect(record.name).to eq 'v3'
        expect(record.lock_version).to eq 3
      end
    end

    describe 'resolve_with auto-detection' do
      temporary_table :auto_resolve_with_lock_version_records do |t|
        t.string :name
        t.integer :lock_version, default: 0
        t.timestamps
      end

      temporary_table :auto_resolve_with_updated_at_records do |t|
        t.string :name
        t.timestamps
      end

      temporary_model :auto_resolve_with_lock_version_record do
        include DualWrites::Model

        dual_writes replicates_to: %i[clickhouse], resolve_with: true
      end

      temporary_model :auto_resolve_with_updated_at_record do
        include DualWrites::Model

        dual_writes replicates_to: %i[clickhouse], resolve_with: true
      end

      it 'should prefer lock_version when present' do
        expect(AutoResolveWithLockVersionRecord.dual_writes_config[:resolve_with]).to eq :lock_version
      end

      it 'should fall back to updated_at when lock_version not present' do
        expect(AutoResolveWithUpdatedAtRecord.dual_writes_config[:resolve_with]).to eq :updated_at
      end
    end

    describe '#perform with append_only strategy' do
      temporary_table :append_only_records do |t|
        t.string :name
        t.text :data
        t.integer :is_deleted, default: 0, null: false
        t.timestamps
      end

      temporary_model :append_only_record do
        include DualWrites::Model

        dual_writes replicates_to: %i[clickhouse], strategy: :append_only
      end

      let(:append_only_model) { AppendOnlyRecord }

      before do
        # Stub the replica class to use the primary model (same table/connection)
        stub_const('AppendOnlyRecord::Clickhouse', append_only_model)
      end

      it 'should configure append_only strategy' do
        expect(append_only_model.dual_writes_config[:strategy]).to eq :append_only
      end

      context 'with create operation' do
        it 'should insert record with is_deleted = 0' do
          record_id = 777_777
          attrs = { 'name' => 'new', 'data' => 'test', 'created_at' => Time.current, 'updated_at' => Time.current }

          job.perform(
            operation: 'create',
            class_name: append_only_model.name,
            primary_key: record_id,
            attributes: attrs,
            shard: 'clickhouse',
          )

          record = append_only_model.find_by(id: record_id)
          expect(record).to be_present
          expect(record.name).to eq 'new'
          expect(record.is_deleted).to eq 0
        end
      end

      context 'with update operation' do
        it 'should insert new version with is_deleted = 0' do
          # In insert-only mode, updates insert new rows rather than updating existing ones
          # ClickHouse ReplacingMergeTree will deduplicate based on the version column
          record_id = 777_778
          attrs = { 'name' => 'updated', 'data' => 'new', 'created_at' => Time.current, 'updated_at' => Time.current }

          job.perform(
            operation: 'update',
            class_name: append_only_model.name,
            primary_key: record_id,
            attributes: attrs,
            shard: 'clickhouse',
          )

          record = append_only_model.find_by(id: record_id)
          expect(record).to be_present
          expect(record.is_deleted).to eq 0
        end
      end

      context 'with destroy operation' do
        it 'should insert tombstone with is_deleted = 1' do
          record_id = 777_779
          attrs = { 'name' => 'deleted', 'data' => 'test', 'created_at' => Time.current, 'updated_at' => Time.current }

          job.perform(
            operation: 'destroy',
            class_name: append_only_model.name,
            primary_key: record_id,
            attributes: attrs,
            shard: 'clickhouse',
          )

          record = append_only_model.find_by(id: record_id)
          expect(record).to be_present
          expect(record.is_deleted).to eq 1
        end
      end
    end

    describe 'strategy validation' do
      it 'should raise error for invalid strategy' do
        expect {
          Class.new(ApplicationRecord) do
            self.table_name = 'replication_test_records'

            include DualWrites::Model

            dual_writes replicates_to: %i[clickhouse], strategy: :invalid
          end
        }.to raise_error(DualWrites::ConfigurationError, /strategy must be :standard or :append_only/)
      end
    end
  end

  describe 'bulk operations' do
    temporary_table :bulk_records do |t|
      t.string :name
      t.text :data
      t.timestamps
    end

    temporary_model :bulk_record do
      include DualWrites::Model

      dual_writes replicates_to: %i[clickhouse]
    end

    let(:model) { BulkRecord }

    describe '.insert_all' do
      it 'should enqueue bulk replication job' do
        attributes = [
          { name: 'record1', data: 'data1' },
          { name: 'record2', data: 'data2' },
        ]

        expect {
          model.insert_all(attributes)
        }.to have_enqueued_job(DualWrites::BulkReplicationJob).with(
          operation: 'insert_all',
          class_name: 'BulkRecord',
          attributes: [
            hash_including('name' => 'record1', 'data' => 'data1'),
            hash_including('name' => 'record2', 'data' => 'data2'),
          ],
          shard: 'clickhouse',
        )
      end

      it 'should insert records into primary' do
        attributes = [
          { name: 'record1', data: 'data1' },
          { name: 'record2', data: 'data2' },
        ]

        expect {
          model.insert_all(attributes)
        }.to change { model.count }.by(2)
      end
    end

    describe '.insert_all!' do
      it 'should enqueue bulk replication job' do
        attributes = [
          { name: 'record1', data: 'data1' },
        ]

        expect {
          model.insert_all!(attributes)
        }.to have_enqueued_job(DualWrites::BulkReplicationJob).with(
          operation: 'insert_all',
          class_name: 'BulkRecord',
          attributes: an_instance_of(Array),
          shard: 'clickhouse',
        )
      end
    end

    describe '.upsert_all' do
      it 'should enqueue bulk replication job' do
        attributes = [
          { name: 'record1', data: 'data1' },
        ]

        expect {
          model.upsert_all(attributes)
        }.to have_enqueued_job(DualWrites::BulkReplicationJob).with(
          operation: 'upsert_all',
          class_name: 'BulkRecord',
          attributes: an_instance_of(Array),
          shard: 'clickhouse',
        )
      end
    end

    describe '.without_dual_writes' do
      it 'should not enqueue bulk replication job' do
        attributes = [{ name: 'record1', data: 'data1' }]

        expect {
          model.without_dual_writes do
            model.insert_all(attributes)
          end
        }.not_to have_enqueued_job(DualWrites::BulkReplicationJob)
      end
    end
  end

  describe DualWrites::BulkReplicationJob do
    let(:job) { DualWrites::BulkReplicationJob.new }

    describe '#perform with standard strategy' do
      temporary_table :bulk_standard_records do |t|
        t.string :name
        t.text :data
        t.timestamps
      end

      temporary_model :bulk_standard_record do
        include DualWrites::Model

        dual_writes replicates_to: %i[replica], strategy: :standard
      end

      let(:model) { BulkStandardRecord }

      before do
        # Stub the replica class to use the primary model (same table/connection)
        stub_const('BulkStandardRecord::Replica', model)
      end

      it 'should insert_all records to replica' do
        attributes = [
          { 'name' => 'record1', 'data' => 'data1' },
          { 'name' => 'record2', 'data' => 'data2' },
        ]

        expect {
          job.perform(
            operation: 'insert_all',
            class_name: model.name,
            attributes: attributes,
            shard: 'replica',
          )
        }.to change { model.count }.by(2)
      end

      it 'should upsert_all records to replica' do
        attributes = [
          { 'name' => 'record1', 'data' => 'data1' },
        ]

        expect {
          job.perform(
            operation: 'upsert_all',
            class_name: model.name,
            attributes: attributes,
            shard: 'replica',
          )
        }.to change { model.count }.by(1)
      end
    end

    describe '#perform with append_only strategy' do
      temporary_table :bulk_append_records do |t|
        t.string :name
        t.text :data
        t.integer :is_deleted, default: 0, null: false
        t.timestamps
      end

      temporary_model :bulk_append_record do
        include DualWrites::Model

        dual_writes replicates_to: %i[clickhouse], strategy: :append_only
      end

      let(:model) { BulkAppendRecord }

      before do
        # Stub the replica class to use the primary model (same table/connection)
        stub_const('BulkAppendRecord::Clickhouse', model)
      end

      it 'should insert_all records with is_deleted = 0' do
        attributes = [
          { 'name' => 'record1', 'data' => 'data1' },
          { 'name' => 'record2', 'data' => 'data2' },
        ]

        job.perform(
          operation: 'insert_all',
          class_name: model.name,
          attributes: attributes,
          shard: 'clickhouse',
        )

        records = model.all
        expect(records.count).to eq 2
        expect(records.all? { |r| r.is_deleted == 0 }).to be true
      end

      it 'should serialize JSON attributes' do
        attributes = [
          { 'name' => 'record1', 'data' => { 'nested' => 'value' } },
        ]

        job.perform(
          operation: 'insert_all',
          class_name: model.name,
          attributes: attributes,
          shard: 'clickhouse',
        )

        record = model.last
        expect(record.data).to eq '{"nested":"value"}'
      end

      it 'should handle upsert_all as insert_all' do
        attributes = [
          { 'name' => 'record1', 'data' => 'data1' },
        ]

        job.perform(
          operation: 'upsert_all',
          class_name: model.name,
          attributes: attributes,
          shard: 'clickhouse',
        )

        record = model.last
        expect(record.is_deleted).to eq 0
      end
    end

    describe '#perform with invalid operation' do
      temporary_model :bulk_invalid_record, table_name: :bulk_records do
        include DualWrites::Model

        dual_writes replicates_to: %i[clickhouse]
      end

      it 'should raise error for unknown operation' do
        expect {
          job.perform(
            operation: 'delete_all',
            class_name: 'BulkInvalidRecord',
            attributes: [],
            shard: 'clickhouse',
          )
        }.to raise_error(DualWrites::ReplicationError, /unknown bulk operation/)
      end
    end
  end
end
