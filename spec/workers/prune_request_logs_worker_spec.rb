# frozen_string_literal: true

require 'rails_helper'
require 'spec_helper'

describe PruneRequestLogsWorker do
  let(:worker) { PruneRequestLogsWorker }

  before { Sidekiq::Testing.inline! }
  after  { Sidekiq::Testing.fake! }

  context 'for ent account' do
    let(:account) { create(:account, :ent) }

    it 'should prune backlog of request logs' do
      create_list(:request_log, 50, account:, created_at: (worker::BACKLOG_DAYS + 1).days.ago)
      create_list(:request_log, 50, account:, created_at: (worker::BACKLOG_DAYS - 1).days.ago)
      create_list(:request_log, 50, account:)

      expect { worker.perform_async }.to(
        change { account.request_logs.count }.from(150).to(100),
      )
    end

    context 'with a request log retention policy' do
      let(:account) { create(:account, plan: build(:plan, :ent, request_log_retention_duration: (worker::BACKLOG_DAYS + 30).days)) }

      it 'should prune according to retention policy' do
        create_list(:request_log, 50, account:, created_at: (worker::BACKLOG_DAYS + 31).days.ago)
        create_list(:request_log, 50, account:, created_at: (worker::BACKLOG_DAYS + 29).days.ago)
        create_list(:request_log, 50, account:, created_at: (worker::BACKLOG_DAYS + 1).days.ago)
        create_list(:request_log, 50, account:, created_at: (worker::BACKLOG_DAYS - 1).days.ago)

        expect { worker.perform_async }.to(
          change { account.request_logs.count }.from(200).to(150),
        )
      end
    end
  end

  context 'for std account' do
    let(:account) { create(:account, :std) }

    it 'should prune backlog of request logs' do
      create_list(:request_log, 50, account:, created_at: (worker::BACKLOG_DAYS + 1).days.ago)
      create_list(:request_log, 50, account:, created_at: (worker::BACKLOG_DAYS - 1).days.ago)
      create_list(:request_log, 50, account:)

      expect { worker.perform_async }.to(
        change { account.request_logs.count }.from(150).to(100),
      )
    end

    context 'with a request log retention policy' do
      let(:account) { create(:account, plan: build(:plan, :std, request_log_retention_duration: (worker::BACKLOG_DAYS + 30).days)) }

      it 'should prune according to retention policy' do
        create_list(:request_log, 50, account:, created_at: (worker::BACKLOG_DAYS + 31).days.ago)
        create_list(:request_log, 50, account:, created_at: (worker::BACKLOG_DAYS + 29).days.ago)
        create_list(:request_log, 50, account:, created_at: (worker::BACKLOG_DAYS + 1).days.ago)
        create_list(:request_log, 50, account:, created_at: (worker::BACKLOG_DAYS - 1).days.ago)

        expect { worker.perform_async }.to(
          change { account.request_logs.count }.from(200).to(50),
        )
      end
    end
  end
end
