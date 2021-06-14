# frozen_string_literal: true

require 'rails_helper'
require 'spec_helper'
require 'database_cleaner'
require 'sidekiq/testing'

DatabaseCleaner.strategy = :truncation, { except: ['event_types'] }

describe LicenseOverdueCheckInsWorker do
  let(:worker) { LicenseOverdueCheckInsWorker }
  let(:account) { create(:account) }

  # See: https://github.com/mhenrixon/sidekiq-unique-jobs#testing
  before do
    Sidekiq::Testing.fake!
    Sidekiq.redis &:flushdb
  end

  after do
    Sidekiq.redis &:flushdb
    Sidekiq::Worker.clear_all
    DatabaseCleaner.clean
  end

  it 'should enqueue and run the worker' do
    worker.perform_async
    expect(worker.jobs.size).to eq 1

    worker.drain
    expect(worker.jobs.size).to eq 0
  end

  context 'when there is a license that has recently become overdue' do
    let(:event) { 'license.check-in-overdue' }

    it 'should send a license.check-in-overdue webhook event' do
      allow(CreateWebhookEventService).to receive(:new).with(hash_including(event: event)).and_call_original
      expect_any_instance_of(CreateWebhookEventService).to receive(:call)

      create :license, :day_check_in, last_check_in_at: 25.hours.ago, account: account

      worker.perform_async
      worker.drain
    end

    it 'should send multiple license.check-in-overdue webhook events' do
      events = 0

      allow(CreateWebhookEventService).to receive(:new).with(hash_including(event: event)).and_call_original
      allow_any_instance_of(CreateWebhookEventService).to receive(:call) { events += 1 }

      create :license, :day_check_in, last_check_in_at: 42.hours.ago, account: account
      create :license, :day_check_in, last_check_in_at: 30.hours.ago, account: account
      create :license, :day_check_in, last_check_in_at: 25.hours.ago, account: account
      create :license, :day_check_in, last_check_in_at: 1.day.ago, account: account
      create :license, :day_check_in, last_check_in_at: 4.days.from_now, account: account

      worker.perform_async
      worker.drain

      expect(events).to eq 3
    end

    it 'should mark the license with the overdue event time' do
      license = create :license, :day_check_in, last_check_in_at: 25.hours.ago, account: account

      worker.perform_async
      worker.drain

      license.reload

      expect(license.last_check_in_event_sent_at).not_to eq nil
    end
  end

  context 'when there is not a license that has recently become overdue' do
    let(:event) { 'license.check-in-overdue' }

    it 'should not send a license.check-in-overdue webhook event' do
      allow(CreateWebhookEventService).to receive(:new).with(hash_including(event: event)).and_call_original
      expect_any_instance_of(CreateWebhookEventService).not_to receive(:call)

      create :license, :week_check_in, last_check_in_at: 3.days.from_now, account: account

      worker.perform_async
      worker.drain
    end

    it 'should not mark the license with the overdue check-in event time' do
      license = create :license, :week_check_in, last_check_in_at: 1.week.from_now, account: account

      worker.perform_async
      worker.drain

      license.reload

      expect(license.last_check_in_event_sent_at).to eq nil
    end
  end

  context 'when there is a license that will become overdue soon' do
    let(:event) { 'license.check-in-required-soon' }

    it 'should send a license.check-in-required-soon webhook event' do
      allow(CreateWebhookEventService).to receive(:new).with(hash_including(event: event)).and_call_original
      expect_any_instance_of(CreateWebhookEventService).to receive(:call)

      create :license, :day_check_in, last_check_in_at: 1.day.from_now, account: account

      worker.perform_async
      worker.drain
    end

    it 'should send multiple license.check-in-required-soon webhook event' do
      events = 0

      allow(CreateWebhookEventService).to receive(:new).with(hash_including(event: event)).and_call_original
      allow_any_instance_of(CreateWebhookEventService).to receive(:call) { events += 1 }

      create :license, :day_check_in, last_check_in_at: 4.days.from_now, account: account
      create :license, :day_check_in, last_check_in_at: 2.days.from_now, account: account
      create :license, :day_check_in, last_check_in_at: 1.day.from_now, account: account
      create :license, :day_check_in, last_check_in_at: 5.hours.from_now, account: account
      create :license, :day_check_in, last_check_in_at: 3.days.ago, account: account

      worker.perform_async
      worker.drain

      expect(events).to eq 3
    end

    it 'should mark the license with the check-in soon event time' do
      license = create :license, :day_check_in, last_check_in_at: 1.day.from_now, account: account

      worker.perform_async
      worker.drain

      license.reload
      expect(license.last_check_in_soon_event_sent_at).not_to eq nil
    end
  end

  context 'when there is not a license that will become overdue soon' do
    let(:event) { 'license.check-in-required-soon' }

    it 'should not send a license.expiring-soon webhook event' do
      allow(CreateWebhookEventService).to receive(:new).with(hash_including(event: event)).and_call_original
      expect_any_instance_of(CreateWebhookEventService).not_to receive(:call)

      create :license, :month_check_in, last_check_in_at: 1.month.from_now, account: account

      worker.perform_async
      worker.drain
    end

    it 'should not mark the license with the check-in soon event time' do
      license = create :license, :year_check_in, last_check_in_at: 4.months.from_now, account: account

      worker.perform_async
      worker.drain

      license.reload
      expect(license.last_check_in_soon_event_sent_at).to eq nil
    end
  end
end
