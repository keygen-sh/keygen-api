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
          to: [:clickhouse],
          strategy: :clickhouse,
          sync: false,
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
        replica_record = RequestLog::Clickhouse.find_by(id: request_log.id)
        expect(replica_record).to be_present
        expect(replica_record.account_id).to eq request_log.account_id
        expect(replica_record.method).to eq request_log.method
        expect(replica_record.url).to eq request_log.url
        expect(replica_record.is_deleted).to eq 0
      end
    end

    describe 'bulk operations' do
      describe '.insert_all' do
        it 'should enqueue bulk replication job' do
          now = Time.current
          attributes = [
            {
              id: SecureRandom.uuid,
              account_id: account.id,
              method: 'GET',
              url: '/v1/accounts',
              status: '200',
              ip: '127.0.0.1',
              created_at: now,
              updated_at: now,
              created_date: now.to_date,
            },
            {
              id: SecureRandom.uuid,
              account_id: account.id,
              method: 'POST',
              url: '/v1/licenses',
              status: '201',
              ip: '127.0.0.1',
              created_at: now,
              updated_at: now,
              created_date: now.to_date,
            },
          ]

          expect {
            RequestLog.insert_all(attributes)
          }.to have_enqueued_job(DualWrites::BulkReplicationJob).with(
            operation: 'insert_all',
            class_name: 'RequestLog',
            attributes: an_instance_of(Array),
            shard: 'clickhouse',
          )
        end

        it 'should insert records into primary' do
          now = Time.current
          attributes = [
            {
              id: SecureRandom.uuid,
              account_id: account.id,
              method: 'GET',
              url: '/v1/accounts',
              status: '200',
              ip: '127.0.0.1',
              created_at: now,
              updated_at: now,
              created_date: now.to_date,
            },
          ]

          expect {
            RequestLog.insert_all(attributes)
          }.to change { RequestLog.count }.by(1)
        end
      end

      describe 'bulk replication' do
        it 'should replicate bulk insert to clickhouse' do
          now = Time.current
          id1 = SecureRandom.uuid
          id2 = SecureRandom.uuid

          attributes = [
            {
              id: id1,
              account_id: account.id,
              method: 'GET',
              url: '/v1/accounts',
              status: '200',
              ip: '127.0.0.1',
              created_at: now,
              updated_at: now,
              created_date: now.to_date,
            },
            {
              id: id2,
              account_id: account.id,
              method: 'POST',
              url: '/v1/licenses',
              status: '201',
              ip: '127.0.0.1',
              created_at: now,
              updated_at: now,
              created_date: now.to_date,
            },
          ]

          RequestLog.insert_all(attributes)

          # Perform the enqueued bulk replication job
          job = ActiveJob::Base.queue_adapter.enqueued_jobs.find { _1['job_class'] == 'DualWrites::BulkReplicationJob' }
          args = ActiveJob::Arguments.deserialize(job['arguments']).first
          DualWrites::BulkReplicationJob.perform_now(**args)

          # Verify records exist in replica (ClickHouse)
          replica1 = RequestLog::Clickhouse.find_by(id: id1)
          expect(replica1).to be_present
          expect(replica1.account_id).to eq account.id
          expect(replica1.method).to eq 'GET'
          expect(replica1.is_deleted).to eq 0

          replica2 = RequestLog::Clickhouse.find_by(id: id2)
          expect(replica2).to be_present
          expect(replica2.account_id).to eq account.id
          expect(replica2.method).to eq 'POST'
          expect(replica2.is_deleted).to eq 0
        end
      end

      describe 'with dual writes disabled' do
        it 'should not enqueue bulk replication job' do
          now = Time.current
          attributes = [
            {
              id: SecureRandom.uuid,
              account_id: account.id,
              method: 'GET',
              url: '/v1/accounts',
              status: '200',
              ip: '127.0.0.1',
              created_at: now,
              updated_at: now,
              created_date: now.to_date,
            },
          ]

          expect {
            RequestLog.without_dual_writes do
              RequestLog.insert_all(attributes)
            end
          }.not_to have_enqueued_job(DualWrites::BulkReplicationJob)
        end
      end
    end
  end
end
