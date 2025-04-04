# frozen_string_literal: true

require 'rails_helper'
require 'spec_helper'

describe PruneEventLogsWorker do
  let(:worker) { PruneEventLogsWorker }

  before { Sidekiq::Testing.inline! }
  after  { Sidekiq::Testing.fake! }

  context 'for ent account' do
    let(:account) { create(:account, :ent) }

    it 'should prune and dedup backlog of event logs' do
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

    it 'should prune dup event logs from backlog' do
      licenses = create_list(:license, 5, account:)

      licenses.each do |license|
        ((worker::BACKLOG_DAYS - 2)..(worker::BACKLOG_DAYS + 2)).each do |i|
          create_list(:event_log, 10, :license_validation_succeeded, account:, resource: license, created_at: i.days.ago)
        end
      end

      expect(account.event_logs.group(:resource_id, :resource_type, :event_type_id, :created_date).reorder(nil).count).to(
        satisfy { |counts|
          counts.all? { |_, count| count == 10 }
        },
      )

      expect { worker.perform_async }.to(
        change { account.event_logs.count }.from(250).to(160),
      )

      expect(account.event_logs.group(:resource_id, :resource_type, :event_type_id, :created_date).reorder(nil).count).to(
        satisfy { |counts|
          counts.all? { |(id, type, event, date), count|
            if date >= worker::BACKLOG_DAYS.days.ago.to_date
              count == 10
            else
              count == 1
            end
          }
        },
      )
    end

    it 'should not prune event logs not in target batch' do
      license = create(:license, account:)

      create_list(:event_log, 50, :license_validation_failed, account:, resource: license, created_at: (worker::BACKLOG_DAYS - 1).days.ago)
      create_list(:event_log, 25, :license_created, account:, resource: license, created_at: (worker::BACKLOG_DAYS - 1).days.ago)
      create_list(:event_log, 50, :license_validation_failed, account:, resource: license)
      create_list(:event_log, 25, :license_created, account:, resource: license)

      expect { worker.perform_async }.to_not(
        change { account.event_logs.count },
      )
    end

    context 'with an event log retention policy' do
      let(:account) { create(:account, plan: build(:plan, :ent, event_log_retention_duration: (worker::BACKLOG_DAYS + 30).days)) }

      it 'should prune according to retention policy' do
        license = create(:license, account:)
        machine = create(:machine, license:)

        # outside retention window
        create_list(:event_log, 50, :license_validation_succeeded, account:, resource: license, created_at: (worker::BACKLOG_DAYS + 31).days.ago)
        create_list(:event_log, 50, :machine_heartbeat_ping, account:, resource: machine, created_at: (worker::BACKLOG_DAYS + 31).days.ago)
        create_list(:event_log, 50, :machine_created, account:, resource: machine, created_at: (worker::BACKLOG_DAYS + 31).days.ago)

        # within retention window
        create_list(:event_log, 50, :license_validation_succeeded, account:, resource: license, created_at: (worker::BACKLOG_DAYS + 29).days.ago)
        create_list(:event_log, 50, :machine_heartbeat_ping, account:, resource: machine, created_at: (worker::BACKLOG_DAYS + 29).days.ago)
        create_list(:event_log, 50, :machine_created, account:, resource: machine, created_at: (worker::BACKLOG_DAYS + 29).days.ago)

        # within target window
        create_list(:event_log, 50, :license_validation_succeeded, account:, resource: license, created_at: (worker::BACKLOG_DAYS + 1).days.ago)
        create_list(:event_log, 50, :machine_heartbeat_ping, account:, resource: machine, created_at: (worker::BACKLOG_DAYS + 1).days.ago)
        create_list(:event_log, 50, :machine_created, account:, resource: machine, created_at: (worker::BACKLOG_DAYS + 1).days.ago)

        # recent
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

    it 'should prune and not dedup backlog of event logs' do
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

    it 'should prune event logs from backlog' do
      licenses = create_list(:license, 5, account:)

      licenses.each do |license|
        ((worker::BACKLOG_DAYS - 2)..(worker::BACKLOG_DAYS + 2)).each do |i|
          create_list(:event_log, 10, :license_validation_succeeded, account:, resource: license, created_at: i.days.ago)
        end
      end

      expect(account.event_logs.group(:resource_id, :resource_type, :event_type_id, :created_date).reorder(nil).count).to(
        satisfy { |counts|
          counts.all? { |_, count| count == 10 }
        },
      )

      expect { worker.perform_async }.to(
        change { account.event_logs.count }.from(250).to(150),
      )

      expect(account.event_logs.group(:resource_id, :resource_type, :event_type_id, :created_date).reorder(nil).count).to(
        satisfy { |counts|
          counts.all? { |(id, type, event, date), count|
            if date >= worker::BACKLOG_DAYS.days.ago.to_date
              count == 10
            else
              count == 0
            end
          }
        },
      )
    end

    it 'should not prune event logs not in target batch' do
      license = create(:license, account:)

      create_list(:event_log, 50, :license_validation_failed, account:, resource: license, created_at: (worker::BACKLOG_DAYS - 1).days.ago)
      create_list(:event_log, 25, :license_created, account:, resource: license, created_at: (worker::BACKLOG_DAYS - 1).days.ago)
      create_list(:event_log, 50, :license_validation_failed, account:, resource: license)
      create_list(:event_log, 25, :license_created, account:, resource: license)

      expect { worker.perform_async }.to_not(
        change { account.event_logs.count },
      )
    end

    context 'with an event log retention policy' do
      let(:account) { create(:account, plan: build(:plan, :std, event_log_retention_duration: (worker::BACKLOG_DAYS + 30).days)) }

      it 'should prune according to retention policy' do
        license = create(:license, account:)
        machine = create(:machine, license:)

        # outside retention window
        create_list(:event_log, 50, :license_validation_succeeded, account:, resource: license, created_at: (worker::BACKLOG_DAYS + 31).days.ago)
        create_list(:event_log, 50, :machine_heartbeat_ping, account:, resource: machine, created_at: (worker::BACKLOG_DAYS + 31).days.ago)

        # within retention window
        create_list(:event_log, 50, :license_validation_succeeded, account:, resource: license, created_at: (worker::BACKLOG_DAYS + 29).days.ago)
        create_list(:event_log, 50, :machine_heartbeat_ping, account:, resource: machine, created_at: (worker::BACKLOG_DAYS + 29).days.ago)

        # within target window
        create_list(:event_log, 50, :license_validation_succeeded, account:, resource: license, created_at: (worker::BACKLOG_DAYS + 1).days.ago)
        create_list(:event_log, 50, :machine_heartbeat_ping, account:, resource: machine, created_at: (worker::BACKLOG_DAYS + 1).days.ago)

        # recent
        create_list(:event_log, 50, :license_validation_succeeded, account:, resource: license, created_at: (worker::BACKLOG_DAYS - 1).day.ago)
        create_list(:event_log, 50, :machine_heartbeat_ping, account:, resource: machine, created_at: (worker::BACKLOG_DAYS - 1).day.ago)

        expect { worker.perform_async }.to(
          change { account.event_logs.count }.from(400).to(100),
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
