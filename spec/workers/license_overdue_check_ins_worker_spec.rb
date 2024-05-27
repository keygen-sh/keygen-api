# frozen_string_literal: true

require 'rails_helper'
require 'spec_helper'

describe LicenseOverdueCheckInsWorker do
  let(:worker) { LicenseOverdueCheckInsWorker }
  let(:account) { create(:account) }

  context 'when there is a license that has recently become overdue' do
    let(:event) { 'license.check-in-overdue' }

    it 'should send a license.check-in-overdue webhook event' do
      expect(BroadcastEventService).to receive(:call) { expect(_1).to include(event:) }.exactly(1).time

      create :license, :day_check_in, last_check_in_at: 25.hours.ago, account: account

      worker.perform_async
      worker.drain
    end

    it 'should send multiple license.check-in-overdue webhook events' do
      expect(BroadcastEventService).to receive(:call) { expect(_1).to include(event:) }.exactly(3).times

      create :license, :day_check_in, last_check_in_at: 42.hours.ago, account: account
      create :license, :day_check_in, last_check_in_at: 30.hours.ago, account: account
      create :license, :day_check_in, last_check_in_at: 25.hours.ago, account: account
      create :license, :day_check_in, last_check_in_at: 1.day.ago, account: account
      create :license, :day_check_in, last_check_in_at: 4.days.from_now, account: account

      worker.perform_async
      worker.drain
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
      expect(BroadcastEventService).to receive(:call) { expect(_1).to include(event:) }.exactly(0).times

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
      expect(BroadcastEventService).to receive(:call) { expect(_1).to include(event:) }.exactly(1).time

      create :license, :day_check_in, last_check_in_at: 1.day.from_now, account: account

      worker.perform_async
      worker.drain
    end

    it 'should send multiple license.check-in-required-soon webhook event' do
      expect(BroadcastEventService).to receive(:call) { expect(_1).to include(event:) }.exactly(3).times

      create :license, :day_check_in, last_check_in_at: 4.days.from_now, account: account
      create :license, :day_check_in, last_check_in_at: 2.days.from_now, account: account
      create :license, :day_check_in, last_check_in_at: 1.day.from_now, account: account
      create :license, :day_check_in, last_check_in_at: 5.hours.from_now, account: account
      create :license, :day_check_in, last_check_in_at: 3.days.ago, account: account

      worker.perform_async
      worker.drain
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
      expect(BroadcastEventService).to receive(:call) { expect(_1).to include(event:) }.exactly(0).times

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
