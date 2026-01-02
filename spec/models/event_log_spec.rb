# frozen_string_literal: true

require 'rails_helper'
require 'spec_helper'

describe EventLog, type: :model do
  it_behaves_like :environmental
  it_behaves_like :accountable

  describe 'dual writes' do
    subject(:event_log) { build(:event_log, account:, resource:, whodunnit:, event_type:) }

    let(:account) { create(:account) }
    let(:resource) { create(:license, account:) }
    let(:whodunnit) { create(:user, account:) }
    let(:event_type) { create(:event_type, event: 'license.created') }

    around do |example|
      original_adapter = ActiveJob::Base.queue_adapter
      ActiveJob::Base.queue_adapter = :test
      example.run
    ensure
      ActiveJob::Base.queue_adapter = original_adapter
    end

    describe 'configuration' do
      it 'should be configured for dual writes' do
        expect(EventLog.dual_writes_config).to include(
          replicates_to: [:clickhouse],
          strategy: :append_only,
          async: true,
        )
      end
    end

    describe 'on create' do
      it 'should enqueue replication job' do
        expect { event_log.save! }.to have_enqueued_job(DualWrites::ReplicationJob).with(
          operation: 'create',
          class_name: 'EventLog',
          primary_key: kind_of(String),
          attributes: hash_including(
            'account_id' => account.id,
            'event_type_id' => event_type.id,
            'resource_type' => resource.class.name,
            'resource_id' => resource.id,
          ),
          shard: 'clickhouse',
        )
      end

      it 'should include all replication attributes' do
        event_log.save!

        job = ActiveJob::Base.queue_adapter.enqueued_jobs.find { _1['job_class'] == 'DualWrites::ReplicationJob' }
        args = ActiveJob::Arguments.deserialize(job['arguments']).first
        attrs = args[:attributes]

        expect(attrs).to include(
          'id' => event_log.id,
          'account_id' => account.id,
          'event_type_id' => event_type.id,
          'created_at' => event_log.created_at,
          'updated_at' => event_log.updated_at,
          'created_date' => event_log.created_date,
          'resource_type' => resource.class.name,
          'resource_id' => resource.id,
          'whodunnit_type' => whodunnit.class.name,
          'whodunnit_id' => whodunnit.id,
        )
      end
    end

    describe 'on update' do
      before { event_log.save! }

      it 'should enqueue replication job' do
        expect { event_log.update!(metadata: { foo: 'bar' }) }.to have_enqueued_job(DualWrites::ReplicationJob).with(
          operation: 'update',
          class_name: 'EventLog',
          primary_key: event_log.id,
          attributes: hash_including('metadata' => { 'foo' => 'bar' }),
          shard: 'clickhouse',
        )
      end
    end

    describe 'on destroy' do
      before { event_log.save! }

      it 'should enqueue replication job' do
        expect { event_log.destroy! }.to have_enqueued_job(DualWrites::ReplicationJob).with(
          operation: 'destroy',
          class_name: 'EventLog',
          primary_key: event_log.id,
          attributes: kind_of(Hash),
          shard: 'clickhouse',
        )
      end
    end

    describe 'with dual writes disabled' do
      it 'should not enqueue replication job' do
        expect {
          EventLog.without_dual_writes do
            event_log.save!
          end
        }.not_to have_enqueued_job(DualWrites::ReplicationJob)
      end
    end

    describe 'append_only strategy' do
      let(:job) { DualWrites::ReplicationJob.new }

      before { event_log.save! }

      it 'should insert on create' do
        new_id = SecureRandom.uuid

        allow(EventLog).to receive(:connected_to).and_yield

        expect {
          job.perform(
            operation: 'create',
            class_name: 'EventLog',
            primary_key: new_id,
            attributes: event_log.attributes.merge('id' => new_id),
            shard: 'clickhouse',
          )
        }.to change { EventLog.count }.by(1)
      end

      it 'should insert on update (append-only)' do
        new_id = SecureRandom.uuid

        allow(EventLog).to receive(:connected_to).and_yield

        expect {
          job.perform(
            operation: 'update',
            class_name: 'EventLog',
            primary_key: new_id,
            attributes: event_log.attributes.merge('id' => new_id, 'metadata' => { 'updated' => true }),
            shard: 'clickhouse',
          )
        }.to change { EventLog.count }.by(1)
      end

      it 'should skip destroy (append-only)' do
        allow(EventLog).to receive(:connected_to).and_yield

        expect {
          job.perform(
            operation: 'destroy',
            class_name: 'EventLog',
            primary_key: event_log.id,
            attributes: {},
            shard: 'clickhouse',
          )
        }.not_to change { EventLog.count }
      end
    end
  end
end
