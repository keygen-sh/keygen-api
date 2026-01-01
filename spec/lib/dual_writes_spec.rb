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

      dual_writes to: :primary, replicates_to: %i[analytics]
    end

    let(:model) { DualWriteRecord }

    describe '.dual_writes' do
      it 'should configure dual writes' do
        expect(model.dual_writes_config).to eq(
          primary: :primary,
          replicates_to: [:analytics],
          async: true,
        )
      end

      it 'should raise error for empty replicates_to' do
        expect {
          Class.new(ApplicationRecord) do
            include DualWrites::Model

            dual_writes to: :primary, replicates_to: []
          end
        }.to raise_error(DualWrites::ConfigurationError, /cannot be empty/)
      end

      it 'should raise error for invalid replicates_to' do
        expect {
          Class.new(ApplicationRecord) do
            include DualWrites::Model

            dual_writes to: :primary, replicates_to: ['analytics']
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
          replica: 'analytics',
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
          replica: 'analytics',
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
          replica: 'analytics',
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
      temporary_model :sync_dual_write_record, table_name: :dual_write_records do
        include DualWrites::Model

        dual_writes to: :primary, replicates_to: %i[analytics], async: true
      end

      let(:sync_model) { SyncDualWriteRecord }

      it 'should switch to sync mode within block' do
        # stub connected_to without yielding to avoid duplicate key errors
        # (we're just testing that no async job is enqueued)
        allow(sync_model).to receive(:connected_to)

        expect {
          sync_model.with_sync_dual_writes do
            sync_model.create!(name: 'test', data: 'hello')
          end
        }.not_to have_enqueued_job(DualWrites::ReplicationJob)
      end

      it 'should revert to async mode after block' do
        allow(sync_model).to receive(:connected_to)

        sync_model.with_sync_dual_writes do
          sync_model.create!(name: 'test', data: 'hello')
        end

        expect(sync_model.dual_writes_config[:async]).to eq true
      end
    end

    describe 'sync replication' do
      temporary_model :sync_replication_record, table_name: :dual_write_records do
        include DualWrites::Model

        dual_writes to: :primary, replicates_to: %i[analytics], async: false
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
        allow(sync_model).to receive(:connected_to)

        expect {
          sync_model.create!(name: 'test', data: 'hello')
        }.not_to have_enqueued_job(DualWrites::ReplicationJob)
      end
    end
  end

  describe DualWrites::ReplicationJob do
    temporary_table :replication_test_records do |t|
      t.string :name
      t.text :data
      t.timestamps
    end

    temporary_model :replication_test_record do
      include DualWrites::Model

      dual_writes to: :primary, replicates_to: %i[analytics]
    end

    let(:model) { ReplicationTestRecord }
    let(:job) { DualWrites::ReplicationJob.new }

    describe '#perform' do
      it 'should raise error for unconfigured model' do
        unconfigured_class = Class.new(ApplicationRecord) do
          self.table_name = 'replication_test_records'
        end

        stub_const('UnconfiguredModel', unconfigured_class)

        expect {
          job.perform(
            operation: 'create',
            class_name: 'UnconfiguredModel',
            primary_key: 999_997,
            attributes: { 'name' => 'test' },
            replica: 'analytics',
          )
        }.to raise_error(DualWrites::ConfigurationError, /not configured for dual writes/)
      end

      context 'with create operation' do
        it 'should create record on replica' do
          record_id = 999_999
          attrs = { 'name' => 'test', 'data' => 'hello', 'created_at' => Time.current, 'updated_at' => Time.current }

          allow(model).to receive(:connected_to).and_yield

          expect {
            job.perform(
              operation: 'create',
              class_name: model.name,
              primary_key: record_id,
              attributes: attrs,
              replica: 'analytics',
            )
          }.to change { model.count }.by(1)

          created = model.find_by(id: record_id)
          expect(created.name).to eq 'test'
          expect(created.data).to eq 'hello'
        end
      end

      context 'with update operation' do
        it 'should update existing record on replica' do
          record = model.create!(name: 'original', data: 'old')

          attrs = record.attributes.merge('name' => 'updated', 'data' => 'new').transform_keys(&:to_s)

          allow(model).to receive(:connected_to).and_yield

          job.perform(
            operation: 'update',
            class_name: model.name,
            primary_key: record.id,
            attributes: attrs,
            replica: 'analytics',
          )

          record.reload
          expect(record.name).to eq 'updated'
          expect(record.data).to eq 'new'
        end

        it 'should create record on replica if not exists' do
          record_id = 999_998
          attrs = { 'id' => record_id, 'name' => 'new', 'data' => 'created', 'created_at' => Time.current, 'updated_at' => Time.current }

          allow(model).to receive(:connected_to).and_yield

          expect {
            job.perform(
              operation: 'update',
              class_name: model.name,
              primary_key: record_id,
              attributes: attrs,
              replica: 'analytics',
            )
          }.to change { model.count }.by(1)

          created = model.find_by(id: record_id)
          expect(created.name).to eq 'new'
        end
      end

      context 'with destroy operation' do
        it 'should delete record from replica' do
          record = model.create!(name: 'test', data: 'hello')
          record_id = record.id

          allow(model).to receive(:connected_to).and_yield

          expect {
            job.perform(
              operation: 'destroy',
              class_name: model.name,
              primary_key: record_id,
              attributes: {},
              replica: 'analytics',
            )
          }.to change { model.count }.by(-1)

          expect(model.find_by(id: record_id)).to be_nil
        end
      end

      context 'with invalid operation' do
        it 'should raise error for unknown operation' do
          allow(model).to receive(:connected_to).and_yield

          expect {
            job.perform(
              operation: 'invalid',
              class_name: model.name,
              primary_key: 999_996,
              attributes: {},
              replica: 'analytics',
            )
          }.to raise_error(DualWrites::ReplicationError, /unknown operation/)
        end
      end
    end
  end
end
