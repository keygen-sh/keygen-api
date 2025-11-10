# frozen_string_literal: true

require 'rails_helper'
require 'spec_helper'

describe PruneEventLogsWorker do
  let(:worker) { PruneEventLogsWorker }

  before { Sidekiq::Testing.inline! }
  after  { Sidekiq::Testing.fake! }

  context 'for ent account' do
    let(:account) { create(:account, :ent) }

    it 'should prune and dedup event logs inside backlog' do
      license = create(:license, account:)
      machine = create(:machine, account:)
      process = create(:process, account:)

      create_list(:event_log, 50, :license_validation_succeeded, account:, resource: license, created_at: (worker::BACKLOG_DAYS + 1).days.ago)
      create_list(:event_log, 50, :license_validation_succeeded, account:, resource: license)
      create_list(:event_log, 50, :license_validation_failed, account:, resource: license, created_at: (worker::BACKLOG_DAYS + 1).days.ago)
      create_list(:event_log, 50, :license_validation_failed, account:, resource: license)
      create_list(:event_log, 50, :machine_heartbeat_ping, account:, resource: machine, created_at: (worker::BACKLOG_DAYS + 1).days.ago)
      create_list(:event_log, 50, :machine_heartbeat_ping, account:, resource: machine)
      create_list(:event_log, 50, :process_heartbeat_ping, account:, resource: process, created_at: (worker::BACKLOG_DAYS + 1).days.ago)
      create_list(:event_log, 50, :process_heartbeat_ping, account:, resource: process)
      create_list(:event_log, 5, :license_created, account:, resource: license, created_at: (worker::BACKLOG_DAYS + 1).days.ago)
      create_list(:event_log, 5, :license_created, account:, resource: license)
      create_list(:event_log, 5, :machine_created, account:, resource: machine, created_at: (worker::BACKLOG_DAYS + 1).days.ago)
      create_list(:event_log, 5, :machine_created, account:, resource: machine)
      create_list(:event_log, 5, :machine_deleted, account:, resource: machine, created_at: (worker::BACKLOG_DAYS + 1).days.ago)
      create_list(:event_log, 5, :machine_deleted, account:, resource: machine)

      expect { worker.perform_async }.to(
        change { account.event_logs.count }.from(430).to(234),
      )
    end

    it 'should not prune event logs outside backlog' do
      license = create(:license, account:)

      create_list(:event_log, 50, :license_validation_failed, account:, resource: license, created_at: (worker::BACKLOG_DAYS - 1).days.ago)
      create_list(:event_log, 25, :license_created, account:, resource: license, created_at: (worker::BACKLOG_DAYS - 1).days.ago)
      create_list(:event_log, 50, :license_validation_failed, account:, resource: license)
      create_list(:event_log, 25, :license_created, account:, resource: license)

      expect { worker.perform_async }.to_not(
        change { account.event_logs.count },
      )
    end

    context 'without an event log retention policy' do
      let(:account) { create(:account, plan: build(:plan, :ent, event_log_retention_duration: nil)) }

      it 'should prune backlog' do
        license = create(:license, account:)
        machine = create(:machine, license:)

        # within target window (prune)
        create_list(:event_log, 50, :license_validation_succeeded, account:, resource: license, created_at: (worker::BACKLOG_DAYS + 31).days.ago)
        create_list(:event_log, 50, :machine_heartbeat_ping, account:, resource: machine, created_at: (worker::BACKLOG_DAYS + 31).days.ago)
        create_list(:event_log, 50, :license_validation_succeeded, account:, resource: license, created_at: (worker::BACKLOG_DAYS + 29).days.ago)
        create_list(:event_log, 50, :machine_heartbeat_ping, account:, resource: machine, created_at: (worker::BACKLOG_DAYS + 29).days.ago)
        create_list(:event_log, 50, :license_validation_succeeded, account:, resource: license, created_at: (worker::BACKLOG_DAYS + 1).days.ago)
        create_list(:event_log, 50, :machine_heartbeat_ping, account:, resource: machine, created_at: (worker::BACKLOG_DAYS + 1).days.ago)

        # recent (keep)
        create_list(:event_log, 50, :license_validation_succeeded, account:, resource: license, created_at: (worker::BACKLOG_DAYS - 1).day.ago)
        create_list(:event_log, 50, :machine_heartbeat_ping, account:, resource: machine, created_at: (worker::BACKLOG_DAYS - 1).day.ago)

        expect { worker.perform_async }.to(
          change { account.event_logs.count }.from(400).to(100),
        )
      end
    end

    context 'with an event log retention policy' do
      let(:account) { create(:account, plan: build(:plan, :ent, event_log_retention_duration: (worker::BACKLOG_DAYS + 90).days)) }

      # use small a batch size assert our batches always move forward
      # even if some logs are retained
      before { stub_const('PruneEventLogsWorker::BATCH_SIZE', 25) }

      it 'should prune according to retention policy' do
        license = create(:license, account:)
        machine = create(:machine, license:)

        # outside retention window (prune)
        create_list(:event_log, 50, :license_validation_succeeded, account:, resource: license, created_at: (worker::BACKLOG_DAYS + 91).days.ago)
        create_list(:event_log, 50, :machine_heartbeat_ping, account:, resource: machine, created_at: (worker::BACKLOG_DAYS + 91).days.ago)
        create_list(:event_log, 50, :machine_created, account:, resource: machine, created_at: (worker::BACKLOG_DAYS + 91).days.ago)

        # within retention window (dedup hi-vol, keep lo-vol)
        create_list(:event_log, 50, :license_validation_succeeded, account:, resource: license, created_at: (worker::BACKLOG_DAYS + 89).days.ago)
        create_list(:event_log, 50, :machine_heartbeat_ping, account:, resource: machine, created_at: (worker::BACKLOG_DAYS + 89).days.ago)
        create_list(:event_log, 50, :machine_created, account:, resource: machine, created_at: (worker::BACKLOG_DAYS + 89).days.ago)

        # within target window (dedup hi-vol, keep lo-vol)
        create_list(:event_log, 50, :license_validation_succeeded, account:, resource: license, created_at: (worker::BACKLOG_DAYS + 1).days.ago)
        create_list(:event_log, 50, :machine_heartbeat_ping, account:, resource: machine, created_at: (worker::BACKLOG_DAYS + 1).days.ago)
        create_list(:event_log, 50, :machine_created, account:, resource: machine, created_at: (worker::BACKLOG_DAYS + 1).days.ago)

        # recent (keep)
        create_list(:event_log, 50, :license_validation_succeeded, account:, resource: license, created_at: (worker::BACKLOG_DAYS - 1).days.ago)
        create_list(:event_log, 50, :machine_heartbeat_ping, account:, resource: machine, created_at: (worker::BACKLOG_DAYS - 1).days.ago)
        create_list(:event_log, 50, :machine_created, account:, resource: machine, created_at: (worker::BACKLOG_DAYS - 1).days.ago)

        expect { worker.perform_async }.to(
          change { account.event_logs.count }.from(600).to(254),
        )
      end
    end
  end

  context 'for std account' do
    let(:account) { create(:account, :std) }

    it 'should prune and dedup event logs inside backlog' do
      license = create(:license, account:)
      machine = create(:machine, account:)
      process = create(:process, account:)

      create_list(:event_log, 50, :license_validation_succeeded, account:, resource: license, created_at: (worker::BACKLOG_DAYS + 1).days.ago)
      create_list(:event_log, 50, :license_validation_succeeded, account:, resource: license)
      create_list(:event_log, 50, :license_validation_failed, account:, resource: license, created_at: (worker::BACKLOG_DAYS + 1).days.ago)
      create_list(:event_log, 50, :license_validation_failed, account:, resource: license)
      create_list(:event_log, 50, :machine_heartbeat_ping, account:, resource: machine, created_at: (worker::BACKLOG_DAYS + 1).days.ago)
      create_list(:event_log, 50, :machine_heartbeat_ping, account:, resource: machine)
      create_list(:event_log, 50, :process_heartbeat_ping, account:, resource: process, created_at: (worker::BACKLOG_DAYS + 1).days.ago)
      create_list(:event_log, 50, :process_heartbeat_ping, account:, resource: process)
      create_list(:event_log, 5, :license_created, account:, resource: license, created_at: (worker::BACKLOG_DAYS + 1).days.ago)
      create_list(:event_log, 5, :license_created, account:, resource: license)
      create_list(:event_log, 5, :machine_created, account:, resource: machine, created_at: (worker::BACKLOG_DAYS + 1).days.ago)
      create_list(:event_log, 5, :machine_created, account:, resource: machine)
      create_list(:event_log, 5, :machine_deleted, account:, resource: machine, created_at: (worker::BACKLOG_DAYS + 1).days.ago)
      create_list(:event_log, 5, :machine_deleted, account:, resource: machine)

      expect { worker.perform_async }.to(
        change { account.event_logs.count }.from(430).to(215),
      )
    end

    it 'should not prune event logs outside backlog' do
      license = create(:license, account:)

      create_list(:event_log, 50, :license_validation_failed, account:, resource: license, created_at: (worker::BACKLOG_DAYS - 1).days.ago)
      create_list(:event_log, 25, :license_created, account:, resource: license, created_at: (worker::BACKLOG_DAYS - 1).days.ago)
      create_list(:event_log, 50, :license_validation_failed, account:, resource: license)
      create_list(:event_log, 25, :license_created, account:, resource: license)

      expect { worker.perform_async }.to_not(
        change { account.event_logs.count },
      )
    end

    context 'without an event log retention policy' do
      let(:account) { create(:account, plan: build(:plan, :std, event_log_retention_duration: nil)) }

      it 'should prune backlog' do
        license = create(:license, account:)
        machine = create(:machine, license:)

        # within target window (prune)
        create_list(:event_log, 50, :license_validation_succeeded, account:, resource: license, created_at: (worker::BACKLOG_DAYS + 4).days.ago)
        create_list(:event_log, 50, :machine_heartbeat_ping, account:, resource: machine, created_at: (worker::BACKLOG_DAYS + 4).days.ago)
        create_list(:event_log, 50, :license_validation_succeeded, account:, resource: license, created_at: (worker::BACKLOG_DAYS + 2).days.ago)
        create_list(:event_log, 50, :machine_heartbeat_ping, account:, resource: machine, created_at: (worker::BACKLOG_DAYS + 2).days.ago)
        create_list(:event_log, 50, :license_validation_succeeded, account:, resource: license, created_at: (worker::BACKLOG_DAYS + 1).days.ago)
        create_list(:event_log, 50, :machine_heartbeat_ping, account:, resource: machine, created_at: (worker::BACKLOG_DAYS + 1).days.ago)

        # recent (keep)
        create_list(:event_log, 50, :license_validation_succeeded, account:, resource: license, created_at: (worker::BACKLOG_DAYS - 1).day.ago)
        create_list(:event_log, 50, :machine_heartbeat_ping, account:, resource: machine, created_at: (worker::BACKLOG_DAYS - 1).day.ago)

        expect { worker.perform_async }.to(
          change { account.event_logs.count }.from(400).to(100),
        )
      end
    end

    context 'with an event log retention policy' do
      let(:account) { create(:account, plan: build(:plan, :std, event_log_retention_duration: (worker::BACKLOG_DAYS + 30).days)) }

      it 'should prune according to retention policy' do
        license = create(:license, account:)
        machine = create(:machine, license:)

        # outside retention window (prune)
        create_list(:event_log, 50, :license_validation_succeeded, account:, resource: license, created_at: (worker::BACKLOG_DAYS + 31).days.ago)
        create_list(:event_log, 50, :machine_heartbeat_ping, account:, resource: machine, created_at: (worker::BACKLOG_DAYS + 31).days.ago)

        # within retention window (dedup hi-vol, keep lo-vol)
        create_list(:event_log, 50, :license_validation_succeeded, account:, resource: license, created_at: (worker::BACKLOG_DAYS + 29).days.ago)
        create_list(:event_log, 50, :machine_heartbeat_ping, account:, resource: machine, created_at: (worker::BACKLOG_DAYS + 29).days.ago)

        # within target window (dedup hi-vol, keep lo-vol)
        create_list(:event_log, 50, :license_validation_succeeded, account:, resource: license, created_at: (worker::BACKLOG_DAYS + 1).days.ago)
        create_list(:event_log, 50, :machine_heartbeat_ping, account:, resource: machine, created_at: (worker::BACKLOG_DAYS + 1).days.ago)

        # recent (keep)
        create_list(:event_log, 50, :license_validation_succeeded, account:, resource: license, created_at: (worker::BACKLOG_DAYS - 1).day.ago)
        create_list(:event_log, 50, :machine_heartbeat_ping, account:, resource: machine, created_at: (worker::BACKLOG_DAYS - 1).day.ago)

        expect { worker.perform_async }.to(
          change { account.event_logs.count }.from(400).to(104),
        )
      end
    end

    it 'should pause after execution timeout' do
      resource = create(:license, account:)

      create_list(:event_log, 50, :license_validation_succeeded, account:, resource:, created_at: (worker::BACKLOG_DAYS + 1).days.ago)

      t  = Time.current.iso8601
      dt = (worker::EXEC_TIMEOUT + 1).seconds

      travel dt do
        expect { worker.perform_async(t) }.to_not(
          change { account.event_logs.count },
        )
      end
    end
  end
end
