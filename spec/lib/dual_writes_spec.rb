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
          ttl: nil,
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
          class_name: 'DualWriteRecord',
          attributes: hash_including(id: a_kind_of(Integer), name: 'test', data: 'hello'),
          performed_at: a_kind_of(ActiveSupport::TimeWithZone),
          operation: :create,
          database: :clickhouse,
        )
      end
    end

    describe 'after_update_commit' do
      it 'should enqueue replication job on update' do
        record = model.create!(name: 'test', data: 'hello')

        expect {
          record.update!(name: 'updated')
        }.to have_enqueued_job(DualWrites::ReplicationJob).with(
          class_name: 'DualWriteRecord',
          attributes: hash_including(id: record.id, name: 'updated'),
          performed_at: a_kind_of(ActiveSupport::TimeWithZone),
          operation: :update,
          database: :clickhouse,
        )
      end
    end

    describe 'after_destroy_commit' do
      it 'should enqueue replication job on destroy' do
        record = model.create!(name: 'test', data: 'hello')

        expect {
          record.destroy!
        }.to have_enqueued_job(DualWrites::ReplicationJob).with(
          class_name: 'DualWriteRecord',
          attributes: hash_including(id: record.id),
          performed_at: a_kind_of(ActiveSupport::TimeWithZone),
          operation: :destroy,
          database: :clickhouse,
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

    describe 'ttl' do
      temporary_table :expiring_records do |t|
        t.string :name
        t.integer :retention_seconds, default: 86_400
        t.timestamps
      end

      temporary_model :expiring_record do
        include DualWrites::Model

        dual_writes to: %i[clickhouse], strategy: :clickhouse,
          ttl: -> { retention_seconds }
      end

      let(:expiring_model) { ExpiringRecord }

      it 'should include ttl in attributes' do
        expect {
          expiring_model.create!(name: 'test', retention_seconds: 7_776_000) # 90 days
        }.to have_enqueued_job(DualWrites::ReplicationJob).with(
          class_name: 'ExpiringRecord',
          attributes: hash_including(ttl: 7_776_000),
          performed_at: a_kind_of(ActiveSupport::TimeWithZone),
          operation: :create,
          database: :clickhouse,
        )
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
            class_name: 'UnconfiguredModel',
            attributes: { name: 'test' },
            performed_at: Time.current,
            operation: :create,
            database: :clickhouse,
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
              class_name: 'InvalidOpRecord',
              attributes: {},
              performed_at: Time.current,
              operation: :invalid,
              database: :clickhouse,
            )
          }.to raise_error(ArgumentError, /unknown operation/)
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
          attrs = { id: 1, name: 'new', data: 'test', created_at: Time.current, updated_at: Time.current }

          job.perform(
            class_name: clickhouse_model.name,
            attributes: attrs,
            performed_at: Time.current,
            operation: :create,
            database: :clickhouse,
          )

          record = clickhouse_model.find_by(id: 1)
          expect(record).to be_present
          expect(record.name).to eq 'new'
          expect(record.is_deleted).to eq 0
        end
      end

      context 'with update operation' do
        it 'should insert new version with is_deleted = 0' do
          # In insert-only mode, updates insert new rows rather than updating existing ones
          # ClickHouse ReplacingMergeTree will deduplicate based on the version column
          attrs = { id: 2, name: 'updated', data: 'new', created_at: Time.current, updated_at: Time.current }

          job.perform(
            class_name: clickhouse_model.name,
            attributes: attrs,
            performed_at: Time.current,
            operation: :update,
            database: :clickhouse,
          )

          record = clickhouse_model.find_by(id: 2)
          expect(record).to be_present
          expect(record.is_deleted).to eq 0
        end
      end

      context 'with destroy operation' do
        it 'should insert tombstone with is_deleted = 1' do
          attrs = { id: 3, name: 'deleted', data: 'test', created_at: Time.current, updated_at: Time.current }

          job.perform(
            class_name: clickhouse_model.name,
            attributes: attrs,
            performed_at: Time.current,
            operation: :destroy,
            database: :clickhouse,
          )

          record = clickhouse_model.find_by(id: 3)
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
          class_name: 'BulkRecord',
          records: [
            hash_including(name: 'record1', data: 'data1'),
            hash_including(name: 'record2', data: 'data2'),
          ],
          performed_at: a_kind_of(ActiveSupport::TimeWithZone),
          operation: :insert_all,
          database: :clickhouse,
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
          class_name: 'BulkRecord',
          records: array_including(*attributes),
          performed_at: a_kind_of(ActiveSupport::TimeWithZone),
          operation: :insert_all,
          database: :clickhouse,
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
          class_name: 'BulkRecord',
          records: array_including(*attributes),
          performed_at: a_kind_of(ActiveSupport::TimeWithZone),
          operation: :upsert_all,
          database: :clickhouse,
        )
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
        records = [
          { 'name' => 'record1', 'data' => 'data1' },
          { 'name' => 'record2', 'data' => 'data2' },
        ]

        job.perform(
          class_name: model.name,
          performed_at: Time.current,
          operation: :insert_all,
          database: :clickhouse,
          records:,
        )

        results = model.all
        expect(results.count).to eq 2
        expect(results.all? { |r| r.is_deleted == 0 }).to be true
      end

      it 'should handle upsert_all as insert_all' do
        records = [
          { 'name' => 'record1', 'data' => 'data1' },
        ]

        job.perform(
          operation: 'upsert_all',
          class_name: model.name,
          records:,
          performed_at: Time.current,
          database: 'clickhouse',
        )

        record = model.last
        expect(record.is_deleted).to eq 0
      end
    end

    describe '#perform' do
      temporary_table :bulk_unconfigured_records do |t|
        t.string :name
        t.timestamps
      end

      temporary_model :bulk_unconfigured_model, table_name: :bulk_unconfigured_records

      it 'should raise error for unconfigured model' do
        expect {
          job.perform(
            class_name: 'BulkUnconfiguredModel',
            records: [{ name: 'test' }],
            performed_at: Time.current,
            operation: :insert_all,
            database: :clickhouse,
          )
        }.to raise_error(DualWrites::ConfigurationError, /not configured for dual writes/)
      end

      context 'with invalid operation' do
        temporary_model :bulk_invalid_record, table_name: :bulk_unconfigured_records do
          include DualWrites::Model

          dual_writes to: %i[clickhouse], strategy: :clickhouse
        end

        it 'should raise error for unknown operation' do
          stub_const('BulkInvalidRecord::Clickhouse', BulkInvalidRecord)

          expect {
            job.perform(
              class_name: 'BulkInvalidRecord',
              records: [],
              performed_at: Time.current,
              operation: :delete_all,
              database: :clickhouse,
            )
          }.to raise_error(ArgumentError, /unknown bulk operation/)
        end
      end
    end
  end
end
