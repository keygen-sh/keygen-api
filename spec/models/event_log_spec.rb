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
          to: [:clickhouse],
          strategy: :clickhouse,
          sync: false,
        )
      end
    end

    describe 'on create' do
      it 'should enqueue replication job' do
        expect { event_log.save! }.to have_enqueued_job(DualWrites::ReplicationJob).with(
          operation: 'create',
          class_name: 'EventLog',
          attributes: hash_including(
            'id' => a_kind_of(String),
            'account_id' => account.id,
            'event_type_id' => event_type.id,
            'resource_type' => resource.class.name,
            'resource_id' => resource.id,
          ),
          performed_at: a_kind_of(ActiveSupport::TimeWithZone),
          database: 'clickhouse',
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
          attributes: hash_including('id' => event_log.id, 'metadata' => { 'foo' => 'bar' }),
          performed_at: a_kind_of(ActiveSupport::TimeWithZone),
          database: 'clickhouse',
        )
      end
    end

    describe 'on destroy' do
      before { event_log.save! }

      it 'should enqueue replication job' do
        expect { event_log.destroy! }.to have_enqueued_job(DualWrites::ReplicationJob).with(
          operation: 'destroy',
          class_name: 'EventLog',
          attributes: hash_including('id' => event_log.id),
          performed_at: a_kind_of(ActiveSupport::TimeWithZone),
          database: 'clickhouse',
        )
      end
    end

    describe 'replication' do
      it 'should replicate record to clickhouse' do
        event_log.save!

        # Perform the enqueued replication job
        job = ActiveJob::Base.queue_adapter.enqueued_jobs.find { _1['job_class'] == 'DualWrites::ReplicationJob' }
        args = ActiveJob::Arguments.deserialize(job['arguments']).first
        DualWrites::ReplicationJob.perform_now(**args)

        # Verify record exists in primary (PostgreSQL)
        primary_record = EventLog.find_by(id: event_log.id)
        expect(primary_record).to be_present

        # Verify record exists in replica (ClickHouse)
        replica_record = EventLog::Clickhouse.find_by(id: event_log.id)
        expect(replica_record).to be_present
        expect(replica_record.account_id).to eq event_log.account_id
        expect(replica_record.event_type_id).to eq event_log.event_type_id
        expect(replica_record.resource_type).to eq event_log.resource_type
        expect(replica_record.resource_id).to eq event_log.resource_id
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
              event_type_id: event_type.id,
              resource_type: resource.class.name,
              resource_id: resource.id,
              whodunnit_type: whodunnit.class.name,
              whodunnit_id: whodunnit.id,
              created_at: now,
              updated_at: now,
              created_date: now.to_date,
            },
            {
              id: SecureRandom.uuid,
              account_id: account.id,
              event_type_id: event_type.id,
              resource_type: resource.class.name,
              resource_id: resource.id,
              whodunnit_type: whodunnit.class.name,
              whodunnit_id: whodunnit.id,
              created_at: now,
              updated_at: now,
              created_date: now.to_date,
            },
          ]

          expect {
            EventLog.insert_all(attributes)
          }.to have_enqueued_job(DualWrites::BulkReplicationJob).with(
            operation: 'insert_all',
            class_name: 'EventLog',
            attributes: an_instance_of(Array),
            performed_at: a_kind_of(ActiveSupport::TimeWithZone),
            database: 'clickhouse',
          )
        end

        it 'should insert records into primary' do
          now = Time.current
          attributes = [
            {
              id: SecureRandom.uuid,
              account_id: account.id,
              event_type_id: event_type.id,
              resource_type: resource.class.name,
              resource_id: resource.id,
              created_at: now,
              updated_at: now,
              created_date: now.to_date,
            },
          ]

          expect {
            EventLog.insert_all(attributes)
          }.to change { EventLog.count }.by(1)
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
              event_type_id: event_type.id,
              resource_type: resource.class.name,
              resource_id: resource.id,
              whodunnit_type: whodunnit.class.name,
              whodunnit_id: whodunnit.id,
              created_at: now,
              updated_at: now,
              created_date: now.to_date,
            },
            {
              id: id2,
              account_id: account.id,
              event_type_id: event_type.id,
              resource_type: resource.class.name,
              resource_id: resource.id,
              whodunnit_type: whodunnit.class.name,
              whodunnit_id: whodunnit.id,
              created_at: now,
              updated_at: now,
              created_date: now.to_date,
            },
          ]

          EventLog.insert_all(attributes)

          # Perform the enqueued bulk replication job
          job = ActiveJob::Base.queue_adapter.enqueued_jobs.find { _1['job_class'] == 'DualWrites::BulkReplicationJob' }
          args = ActiveJob::Arguments.deserialize(job['arguments']).first
          DualWrites::BulkReplicationJob.perform_now(**args)

          # Verify records exist in replica (ClickHouse)
          replica1 = EventLog::Clickhouse.find_by(id: id1)
          expect(replica1).to be_present
          expect(replica1.account_id).to eq account.id
          expect(replica1.event_type_id).to eq event_type.id
          expect(replica1.is_deleted).to eq 0

          replica2 = EventLog::Clickhouse.find_by(id: id2)
          expect(replica2).to be_present
          expect(replica2.account_id).to eq account.id
          expect(replica2.event_type_id).to eq event_type.id
          expect(replica2.is_deleted).to eq 0
        end
      end

    end
  end
end
