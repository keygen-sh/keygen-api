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

      dual_writes to: %i[clickhouse], strategy: :clickhouse
    end

    let(:model) { DualWriteRecord }

    describe '.dual_writes' do
      it 'should configure dual writes' do
        expect(model.dual_writes_config).to eq(
          to: [:clickhouse],
          sync: false,
          strategy: :clickhouse,
        )
      end

      it 'should raise error for empty to' do
        expect {
          Class.new(ApplicationRecord) do
            include DualWrites::Model

            dual_writes to: [], strategy: :clickhouse
          end
        }.to raise_error(DualWrites::ConfigurationError, /cannot be empty/)
      end

      it 'should raise error for invalid to' do
        expect {
          Class.new(ApplicationRecord) do
            include DualWrites::Model

            dual_writes to: ['clickhouse'], strategy: :clickhouse
          end
        }.to raise_error(DualWrites::ConfigurationError, /must be a symbol or array of symbols/)
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
          database: 'clickhouse',
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
          database: 'clickhouse',
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
          database: 'clickhouse',
        )
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

        dual_writes to: %i[clickhouse], strategy: :clickhouse, sync: true
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
            database: 'clickhouse',
          )
        }.to raise_error(DualWrites::ConfigurationError, /not configured for dual writes/)
      end

      context 'with invalid operation' do
        temporary_model :invalid_op_record, table_name: :replication_test_records do
          include DualWrites::Model

          dual_writes to: %i[clickhouse], strategy: :clickhouse
        end

        it 'should raise error for unknown operation' do
          stub_const('InvalidOpRecord::Clickhouse', InvalidOpRecord)

          expect {
            job.perform(
              operation: 'invalid',
              class_name: 'InvalidOpRecord',
              primary_key: 999_996,
              attributes: {},
              database: 'clickhouse',
            )
          }.to raise_error(DualWrites::ReplicationError, /unknown operation/)
        end
      end
    end

    describe '#perform with clickhouse strategy' do
      temporary_table :clickhouse_strategy_records do |t|
        t.string :name
        t.text :data
        t.integer :is_deleted, default: 0, null: false
        t.timestamps
      end

      temporary_model :clickhouse_strategy_record do
        include DualWrites::Model

        dual_writes to: %i[clickhouse], strategy: :clickhouse
      end

      let(:clickhouse_model) { ClickhouseStrategyRecord }

      before do
        # Stub the replica class to use the primary model (same table/connection)
        stub_const('ClickhouseStrategyRecord::Clickhouse', clickhouse_model)
      end

      it 'should configure clickhouse strategy' do
        expect(clickhouse_model.dual_writes_config[:strategy]).to eq :clickhouse
      end

      context 'with create operation' do
        it 'should insert record with is_deleted = 0' do
          record_id = 777_777
          attrs = { 'name' => 'new', 'data' => 'test', 'created_at' => Time.current, 'updated_at' => Time.current }

          job.perform(
            operation: 'create',
            class_name: clickhouse_model.name,
            primary_key: record_id,
            attributes: attrs,
            database: 'clickhouse',
          )

          record = clickhouse_model.find_by(id: record_id)
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
            class_name: clickhouse_model.name,
            primary_key: record_id,
            attributes: attrs,
            database: 'clickhouse',
          )

          record = clickhouse_model.find_by(id: record_id)
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
            class_name: clickhouse_model.name,
            primary_key: record_id,
            attributes: attrs,
            database: 'clickhouse',
          )

          record = clickhouse_model.find_by(id: record_id)
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

            dual_writes to: %i[clickhouse], strategy: :invalid
          end
        }.to raise_error(DualWrites::ConfigurationError, /unknown strategy/)
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

      dual_writes to: %i[clickhouse], strategy: :clickhouse
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
          database: 'clickhouse',
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
          database: 'clickhouse',
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
          database: 'clickhouse',
        )
      end
    end

    describe '.delete_all' do
      before do
        model.insert_all([
          { name: 'record1', data: 'data1' },
          { name: 'record2', data: 'data2' },
        ])
      end

      it 'should enqueue bulk replication job with query' do
        expect {
          model.where(name: 'record1').delete_all
        }.to have_enqueued_job(DualWrites::BulkReplicationJob).with(
          operation: 'delete_all',
          class_name: 'BulkRecord',
          query: { where: { 'name' => 'record1' }, order: [], limit: nil, offset: nil },
          database: 'clickhouse',
        )
      end

      it 'should include limit and order in query' do
        expect {
          model.where(name: 'record1').order(:id).limit(10).delete_all
        }.to have_enqueued_job(DualWrites::BulkReplicationJob).with(
          operation: 'delete_all',
          class_name: 'BulkRecord',
          query: hash_including(where: { 'name' => 'record1' }, limit: 10),
          database: 'clickhouse',
        )
      end

      it 'should delete records from primary' do
        expect {
          model.where(name: 'record1').delete_all
        }.to change { model.count }.by(-1)
      end

      it 'should not enqueue job without conditions' do
        expect {
          model.delete_all
        }.not_to have_enqueued_job(DualWrites::BulkReplicationJob)
      end
    end

  end

  describe DualWrites::BulkReplicationJob do
    let(:job) { DualWrites::BulkReplicationJob.new }

    describe '#perform with clickhouse strategy' do
      temporary_table :bulk_clickhouse_records do |t|
        t.string :name
        t.text :data
        t.integer :is_deleted, default: 0, null: false
        t.timestamps
      end

      temporary_model :bulk_clickhouse_record do
        include DualWrites::Model

        dual_writes to: %i[clickhouse], strategy: :clickhouse
      end

      let(:model) { BulkClickhouseRecord }

      before do
        # Stub the replica class to use the primary model (same table/connection)
        stub_const('BulkClickhouseRecord::Clickhouse', model)
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
          database: 'clickhouse',
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
          database: 'clickhouse',
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
          database: 'clickhouse',
        )

        record = model.last
        expect(record.is_deleted).to eq 0
      end

      it 'should handle delete_all with query' do
        # First insert some records
        model.insert_all!([
          { name: 'record1', data: 'data1', is_deleted: 0 },
          { name: 'record2', data: 'data2', is_deleted: 0 },
        ])

        expect(model.count).to eq 2

        # Now delete with query
        job.perform(
          operation: 'delete_all',
          class_name: model.name,
          query: { where: { 'name' => 'record1' }, order: [], limit: nil, offset: nil },
          database: 'clickhouse',
        )

        expect(model.count).to eq 1
        expect(model.first.name).to eq 'record2'
      end

      it 'should handle delete_all with limit' do
        # First insert some records
        model.insert_all!([
          { name: 'record1', data: 'data1', is_deleted: 0 },
          { name: 'record1', data: 'data2', is_deleted: 0 },
          { name: 'record1', data: 'data3', is_deleted: 0 },
        ])

        expect(model.count).to eq 3

        # Delete with limit
        job.perform(
          operation: 'delete_all',
          class_name: model.name,
          query: { where: { 'name' => 'record1' }, order: [], limit: 2, offset: nil },
          database: 'clickhouse',
        )

        expect(model.count).to eq 1
      end
    end

    describe '#perform with invalid operation' do
      temporary_model :bulk_invalid_record, table_name: :bulk_records do
        include DualWrites::Model

        dual_writes to: %i[clickhouse], strategy: :clickhouse
      end

      it 'should raise error for unknown operation' do
        stub_const('BulkInvalidRecord::Clickhouse', BulkInvalidRecord)

        expect {
          job.perform(
            operation: 'invalid',
            class_name: 'BulkInvalidRecord',
            attributes: [],
            database: 'clickhouse',
          )
        }.to raise_error(DualWrites::ReplicationError, /unknown bulk operation/)
      end
    end
  end
end
