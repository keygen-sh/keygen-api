# frozen_string_literal: true

require 'rails_helper'
require 'spec_helper'

describe PruneRequestLogsWorker do
  let(:worker)  { PruneRequestLogsWorker }
  let(:account) { create(:account) }

  before { Sidekiq::Testing.inline! }
  after  { Sidekiq::Testing.fake! }

  it 'should prune backlog of request logs' do
    create_list(:request_log, 50, account:, created_at: worker::BACKLOG_DAYS.days.ago)
    create_list(:request_log, 50, account:)

    expect { worker.perform_async }.to(
      change { account.request_logs.count }.from(100).to(50),
    )
  end
end
