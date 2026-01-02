# frozen_string_literal: true

require 'rails_helper'
require 'spec_helper'

describe RequestLog, type: :model do
  it_behaves_like :environmental
  it_behaves_like :accountable

  describe 'dual writes' do
    subject(:request_log) { build(:request_log, account:) }

    let(:account) { create(:account) }

    around do |example|
      original_adapter = ActiveJob::Base.queue_adapter
      ActiveJob::Base.queue_adapter = :test
      example.run
    ensure
      ActiveJob::Base.queue_adapter = original_adapter
    end

    describe 'configuration' do
      it 'should be configured for dual writes' do
        expect(RequestLog.dual_writes_config).to include(
          replicates_to: [:clickhouse],
          strategy: :append_only,
          async: true,
        )
      end
    end

    describe 'on create' do
      it 'should enqueue replication job' do
        expect { request_log.save! }.to have_enqueued_job(DualWrites::ReplicationJob).with(
          operation: 'create',
          class_name: 'RequestLog',
          primary_key: kind_of(String),
          attributes: hash_including(
            'account_id' => account.id,
            'method' => request_log.method,
            'url' => request_log.url,
          ),
          shard: 'clickhouse',
        )
      end

      it 'should include all replication attributes' do
        request_log.save!

        job = ActiveJob::Base.queue_adapter.enqueued_jobs.find { _1['job_class'] == 'DualWrites::ReplicationJob' }
        args = ActiveJob::Arguments.deserialize(job['arguments']).first
        attrs = args[:attributes]

        expect(attrs).to include(
          'id' => request_log.id,
          'account_id' => account.id,
          'created_at' => request_log.created_at,
          'updated_at' => request_log.updated_at,
          'created_date' => request_log.created_date,
          'requestor_type' => request_log.requestor_type,
          'requestor_id' => request_log.requestor_id,
          'resource_type' => request_log.resource_type,
          'resource_id' => request_log.resource_id,
        )
      end
    end

    describe 'on update' do
      before { request_log.save! }

      it 'should enqueue replication job' do
        expect { request_log.update!(status: '404') }.to have_enqueued_job(DualWrites::ReplicationJob).with(
          operation: 'update',
          class_name: 'RequestLog',
          primary_key: request_log.id,
          attributes: hash_including('status' => '404'),
          shard: 'clickhouse',
        )
      end
    end

    describe 'on destroy' do
      before { request_log.save! }

      it 'should enqueue replication job' do
        expect { request_log.destroy! }.to have_enqueued_job(DualWrites::ReplicationJob).with(
          operation: 'destroy',
          class_name: 'RequestLog',
          primary_key: request_log.id,
          attributes: kind_of(Hash),
          shard: 'clickhouse',
        )
      end
    end

    describe 'with dual writes disabled' do
      it 'should not enqueue replication job' do
        expect {
          RequestLog.without_dual_writes do
            request_log.save!
          end
        }.not_to have_enqueued_job(DualWrites::ReplicationJob)
      end
    end

    describe 'append_only strategy' do
      let(:job) { DualWrites::ReplicationJob.new }

      before { request_log.save! }

      it 'should insert on create' do
        new_id = SecureRandom.uuid

        allow(RequestLog).to receive(:connected_to).and_yield

        expect {
          job.perform(
            operation: 'create',
            class_name: 'RequestLog',
            primary_key: new_id,
            attributes: request_log.attributes.merge('id' => new_id),
            shard: 'clickhouse',
          )
        }.to change { RequestLog.count }.by(1)
      end

      it 'should insert on update (append-only)' do
        # simulate a record that exists in Postgres but not yet replicated to ClickHouse
        new_id = SecureRandom.uuid

        allow(RequestLog).to receive(:connected_to).and_yield

        # append_only inserts a new row on update (ClickHouse ReplacingMergeTree deduplicates later)
        expect {
          job.perform(
            operation: 'update',
            class_name: 'RequestLog',
            primary_key: new_id,
            attributes: request_log.attributes.merge('id' => new_id, 'status' => '500'),
            shard: 'clickhouse',
          )
        }.to change { RequestLog.count }.by(1)
      end

      it 'should skip destroy (append-only)' do
        allow(RequestLog).to receive(:connected_to).and_yield

        # append_only skips deletes
        expect {
          job.perform(
            operation: 'destroy',
            class_name: 'RequestLog',
            primary_key: request_log.id,
            attributes: {},
            shard: 'clickhouse',
          )
        }.not_to change { RequestLog.count }
      end
    end
  end
end
