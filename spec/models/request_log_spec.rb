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

    describe 'replication' do
      it 'should replicate record to clickhouse' do
        request_log.save!

        # Perform the enqueued replication job
        job = ActiveJob::Base.queue_adapter.enqueued_jobs.find { _1['job_class'] == 'DualWrites::ReplicationJob' }
        args = ActiveJob::Arguments.deserialize(job['arguments']).first
        DualWrites::ReplicationJob.perform_now(**args)

        # Verify record exists in primary (PostgreSQL)
        primary_record = RequestLog.find_by(id: request_log.id)
        expect(primary_record).to be_present

        # Verify record exists in replica (ClickHouse)
        ActiveRecord::Base.connected_to(shard: :clickhouse, role: :writing) do
          replica_record = RequestLog.find_by(id: request_log.id)
          expect(replica_record).to be_present
          expect(replica_record.account_id).to eq request_log.account_id
          expect(replica_record.method).to eq request_log.method
          expect(replica_record.url).to eq request_log.url
          expect(replica_record.is_deleted).to eq 0
        end
      end
    end
  end
end
