# frozen_string_literal: true

require 'rails_helper'
require 'spec_helper'

describe PruneWebhookEventsWorker do
  let(:worker)  { PruneWebhookEventsWorker }
  let(:account) { create(:account) }

  # See: https://github.com/mhenrixon/sidekiq-unique-jobs#testing
  before do
    Sidekiq::Testing.inline!
  end

  after do
    Sidekiq::Worker.clear_all
  end

  it 'should prune backlog of webhook events' do
    create_list(:webhook_event, 50, account:, created_at: (worker::BACKLOG_DAYS + 1).days.ago)
    create_list(:webhook_event, 50, account:)

    expect { worker.perform_async }.to(
      change { account.webhook_events.count }.from(100).to(50),
    )
  end
end
