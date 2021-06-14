# frozen_string_literal: true

require 'rails_helper'
require 'spec_helper'
require 'database_cleaner'
require 'sidekiq/testing'

DatabaseCleaner.strategy = :truncation, { except: ['event_types'] }

describe LicenseExpirationsWorker do
  let(:worker) { LicenseExpirationsWorker }
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

  context 'when there is a license that has recently expired' do
    let(:event) { 'license.expired' }

    it 'should send a license.expired webhook event' do
      allow(CreateWebhookEventService).to receive(:new).with(hash_including(event: event)).and_call_original
      expect_any_instance_of(CreateWebhookEventService).to receive(:call)

      create :license, expiry: Time.current, account: account

      worker.perform_async
      worker.drain
    end

    it 'should send multiple license.expired webhook events' do
      events = 0

      allow(CreateWebhookEventService).to receive(:new).with(hash_including(event: event)).and_call_original
      allow_any_instance_of(CreateWebhookEventService).to receive(:call) { events += 1 }

      create :license, expiry: Time.current, account: account
      create :license, expiry: Time.current, account: account
      create :license, expiry: Time.current, account: account
      create :license, expiry: 5.days.from_now, account: account
      create :license, expiry: 5.days.ago, account: account

      worker.perform_async
      worker.drain

      expect(events).to eq 3
    end

    it 'should mark the license with the expiration event time' do
      license = create :license, expiry: 4.hours.ago, account: account

      worker.perform_async
      worker.drain

      license.reload

      expect(license.last_expiration_event_sent_at).not_to eq nil
    end
  end

  context 'when there is not a license that has recently expired' do
    let(:event) { 'license.expired' }

    it 'should not send a license.expired webhook event' do
      allow(CreateWebhookEventService).to receive(:new).with(hash_including(event: event)).and_call_original
      expect_any_instance_of(CreateWebhookEventService).not_to receive(:call)

      create :license, expiry: 7.days.from_now, account: account

      worker.perform_async
      worker.drain
    end

    it 'should not mark the license with the expiration event time' do
      license = create :license, expiry: 15.hours.ago, account: account

      worker.perform_async
      worker.drain

      license.reload

      expect(license.last_expiration_event_sent_at).to eq nil
    end
  end

  context 'when there is a license that is expiring soon' do
    let(:event) { 'license.expiring-soon' }

    it 'should send a license.expiring-soon webhook event' do
      allow(CreateWebhookEventService).to receive(:new).with(hash_including(event: event)).and_call_original
      expect_any_instance_of(CreateWebhookEventService).to receive(:call)

      create :license, expiry: 2.days.from_now, account: account

      worker.perform_async
      worker.drain
    end

    it 'should send multiple license.expiring-soon webhook event' do
      events = 0

      allow(CreateWebhookEventService).to receive(:new).with(hash_including(event: event)).and_call_original
      allow_any_instance_of(CreateWebhookEventService).to receive(:call) { events += 1 }

      create :license, expiry: 2.days.from_now, account: account
      create :license, expiry: 1.day.from_now, account: account
      create :license, expiry: 5.hours.from_now, account: account
      create :license, expiry: 1.hour.from_now, account: account
      create :license, expiry: 18.hours.ago, account: account

      worker.perform_async
      worker.drain

      expect(events).to eq 4
    end

    it 'should mark the license with the expiring soon event time' do
      license = create :license, expiry: 1.day.from_now, account: account

      worker.perform_async
      worker.drain

      license.reload
      expect(license.last_expiring_soon_event_sent_at).not_to eq nil
    end
  end

  context 'when there is not a license that is expiring soon' do
    let(:event) { 'license.expiring-soon' }

    it 'should not send a license.expiring-soon webhook event' do
      allow(CreateWebhookEventService).to receive(:new).with(hash_including(event: event)).and_call_original
      expect_any_instance_of(CreateWebhookEventService).not_to receive(:call)

      create :license, expiry: 9.days.from_now, account: account

      worker.perform_async
      worker.drain
    end

    it 'should not mark the license with the expiring soon event time' do
      license = create :license, expiry: 4.days.from_now, account: account

      worker.perform_async
      worker.drain

      license.reload
      expect(license.last_expiring_soon_event_sent_at).to eq nil
    end
  end
end
