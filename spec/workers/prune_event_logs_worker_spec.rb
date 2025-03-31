# frozen_string_literal: true

require 'rails_helper'
require 'spec_helper'

describe PruneEventLogsWorker do
  let(:worker)  { PruneEventLogsWorker }

  before { Sidekiq::Testing.inline! }
  after  { Sidekiq::Testing.fake! }

  context 'for ent account' do
    let(:account) { create(:account, :ent) }

    it 'should prune backlog of high-volume event logs' do
      license = create(:license, account:)
      machine = create(:machine, account:)
      process = create(:process, account:)

      create_list(:event_log, 50, :license_validation_succeeded, account:, resource: license, created_at: worker::BACKLOG_DAYS.days.ago)
      create_list(:event_log, 50, :license_validation_succeeded, account:, resource: license)
      create_list(:event_log, 50, :license_validation_failed, account:, resource: license, created_at: worker::BACKLOG_DAYS.days.ago)
      create_list(:event_log, 50, :license_validation_failed, account:, resource: license)
      create_list(:event_log, 50, :machine_heartbeat_ping, account:, resource: machine, created_at: worker::BACKLOG_DAYS.days.ago)
      create_list(:event_log, 50, :machine_heartbeat_ping, account:, resource: machine)
      create_list(:event_log, 50, :process_heartbeat_ping, account:, resource: process, created_at: worker::BACKLOG_DAYS.days.ago)
      create_list(:event_log, 50, :process_heartbeat_ping, account:, resource: process)
      create_list(:event_log, 5, :license_created, account:, resource: license, created_at: worker::BACKLOG_DAYS.days.ago)
      create_list(:event_log, 5, :license_created, account:, resource: license)
      create_list(:event_log, 5, :machine_created, account:, resource: machine, created_at: worker::BACKLOG_DAYS.days.ago)
      create_list(:event_log, 5, :machine_created, account:, resource: machine)
      create_list(:event_log, 5, :machine_deleted, account:, resource: machine, created_at: worker::BACKLOG_DAYS.days.ago)
      create_list(:event_log, 5, :machine_deleted, account:, resource: machine)

      expect { worker.perform_async }.to(
        change { account.event_logs.count }.from(430).to(234),
      )
    end

    it 'should prune duplicate event logs from backlog' do
      licenses = create_list(:license, 5, account:)

      licenses.each do |license|
        ((worker::BACKLOG_DAYS - 2)..worker::BACKLOG_DAYS).each do |i|
          create_list(:event_log, 10, :license_validation_succeeded, account:, resource: license, created_at: i.days.ago)
        end
      end

      expect(account.event_logs.group(:resource_id, :resource_type, :event_type_id, :created_date).reorder(nil).count).to(
        satisfy { |counts|
          counts.all? { |_, count| count == 10 }
        },
      )

      expect { worker.perform_async }.to(
        change { account.event_logs.count }.from(150).to(105),
      )

      expect(account.event_logs.group(:resource_id, :resource_type, :event_type_id, :created_date).reorder(nil).count).to(
        satisfy { |counts|
          counts.all? { |(id, type, event, date), count|
            if date > worker::BACKLOG_DAYS.days.ago.to_date
              count == 10
            else
              count == 1
            end
          }
        },
      )
    end

    it 'should not prune high-volume event logs not in target batch' do
      license = create(:license, account:)

      create_list(:event_log, 50, :license_validation_failed, account:, resource: license, created_at: (worker::BACKLOG_DAYS - 1).days.ago)
      create_list(:event_log, 50, :license_validation_failed, account:, resource: license)

      expect { worker.perform_async }.to_not(
        change { account.event_logs.count },
      )
    end
  end

  context 'for std account' do
    let(:account) { create(:account, :std) }

    it 'should prune backlog of high-volume event logs' do
      license = create(:license, account:)
      machine = create(:machine, account:)
      process = create(:process, account:)

      create_list(:event_log, 50, :license_validation_succeeded, account:, resource: license, created_at: worker::BACKLOG_DAYS.days.ago)
      create_list(:event_log, 50, :license_validation_succeeded, account:, resource: license)
      create_list(:event_log, 50, :license_validation_failed, account:, resource: license, created_at: worker::BACKLOG_DAYS.days.ago)
      create_list(:event_log, 50, :license_validation_failed, account:, resource: license)
      create_list(:event_log, 50, :machine_heartbeat_ping, account:, resource: machine, created_at: worker::BACKLOG_DAYS.days.ago)
      create_list(:event_log, 50, :machine_heartbeat_ping, account:, resource: machine)
      create_list(:event_log, 50, :process_heartbeat_ping, account:, resource: process, created_at: worker::BACKLOG_DAYS.days.ago)
      create_list(:event_log, 50, :process_heartbeat_ping, account:, resource: process)
      create_list(:event_log, 5, :license_created, account:, resource: license, created_at: worker::BACKLOG_DAYS.days.ago)
      create_list(:event_log, 5, :license_created, account:, resource: license)
      create_list(:event_log, 5, :machine_created, account:, resource: machine, created_at: worker::BACKLOG_DAYS.days.ago)
      create_list(:event_log, 5, :machine_created, account:, resource: machine)
      create_list(:event_log, 5, :machine_deleted, account:, resource: machine, created_at: worker::BACKLOG_DAYS.days.ago)
      create_list(:event_log, 5, :machine_deleted, account:, resource: machine)

      expect { worker.perform_async }.to(
        change { account.event_logs.count }.from(430).to(215),
      )
    end

    it 'should prune event logs from backlog' do
      licenses = create_list(:license, 5, account:)

      licenses.each do |license|
        ((worker::BACKLOG_DAYS - 2)..worker::BACKLOG_DAYS).each do |i|
          create_list(:event_log, 10, :license_validation_succeeded, account:, resource: license, created_at: i.days.ago)
        end
      end

      expect(account.event_logs.group(:resource_id, :resource_type, :event_type_id, :created_date).reorder(nil).count).to(
        satisfy { |counts|
          counts.all? { |_, count| count == 10 }
        },
      )

      expect { worker.perform_async }.to(
        change { account.event_logs.count }.from(150).to(100),
      )

      expect(account.event_logs.group(:resource_id, :resource_type, :event_type_id, :created_date).reorder(nil).count).to(
        satisfy { |counts|
          counts.all? { |(id, type, event, date), count|
            if date > worker::BACKLOG_DAYS.days.ago.to_date
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
      create_list(:event_log, 50, :license_validation_failed, account:, resource: license)

      expect { worker.perform_async }.to_not(
        change { account.event_logs.count },
      )
    end
  end
end
