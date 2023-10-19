# frozen_string_literal: true

require 'rails_helper'
require 'spec_helper'

describe PruneRequestLogsWorker do
  let(:worker)  { PruneRequestLogsWorker }
  let(:account) { create(:account) }

  # See: https://github.com/mhenrixon/sidekiq-unique-jobs#testing
  before do
    Sidekiq::Testing.inline!
  end

  after do
    Sidekiq::Worker.clear_all
  end

  it 'should prune backlog of request logs' do
    create_list(:request_log, 50, account:, created_at: (worker::BACKLOG_DAYS + 1).days.ago)
    create_list(:request_log, 50, account:)

    expect { worker.perform_async }.to(
      change { account.request_logs.count }.from(100).to(50),
    )
  end
end
