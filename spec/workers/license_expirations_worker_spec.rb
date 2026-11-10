# frozen_string_literal: true

require 'rails_helper'
require 'spec_helper'

describe LicenseExpirationsWorker do
  let(:worker) { LicenseExpirationsWorker }
  let(:account) { create(:account) }

  context 'when there is a license that has recently expired' do
    let(:event) { 'license.expired' }

    it 'should send a license.expired webhook event' do
      expect(BroadcastEventService).to receive(:call) { expect(it).to include(event:) }.exactly(1).time

      create :license, expiry: Time.current, account: account

      worker.perform_async
      worker.drain
    end

    it 'should send multiple license.expired webhook events' do
      expect(BroadcastEventService).to receive(:call) { expect(it).to include(event:) }.exactly(3).times

      create :license, expiry: Time.current, account: account
      create :license, expiry: Time.current, account: account
      create :license, expiry: Time.current, account: account
      create :license, expiry: 5.days.from_now, account: account
      create :license, expiry: 5.days.ago, account: account

      worker.perform_async
      worker.drain
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
      expect(BroadcastEventService).to receive(:call) { expect(it).to include(event:) }.exactly(0).times

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
      expect(BroadcastEventService).to receive(:call) { expect(it).to include(event:) }.exactly(1).time

      create :license, expiry: 2.days.from_now, account: account

      worker.perform_async
      worker.drain
    end

    it 'should send multiple license.expiring-soon webhook event' do
      expect(BroadcastEventService).to receive(:call) { expect(it).to include(event:) }.exactly(4).times

      create :license, expiry: 2.days.from_now, account: account
      create :license, expiry: 1.day.from_now, account: account
      create :license, expiry: 5.hours.from_now, account: account
      create :license, expiry: 1.hour.from_now, account: account
      create :license, expiry: 18.hours.ago, account: account

      worker.perform_async
      worker.drain
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
      expect(BroadcastEventService).to receive(:call) { expect(it).to include(event:) }.exactly(0).times

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

  context 'when there is a license that auto-renews' do
    let(:event)  { 'license.renewed' }
    let(:policy) { create(:policy, account:, duration: 1.month, renewal_strategy: 'AUTO_RENEW') }

    it 'should renew a license that is about to expire' do
      expect(BroadcastEventService).to receive(:call) { expect(it).to include(event:) }.exactly(1).time

      freeze_time do
        license = create(:license, account:, policy:, expiry: 5.minutes.from_now)

        worker.perform_async
        worker.drain

        expect(license.reload.expiry).to eq 5.minutes.from_now + 1.month
      end
    end

    it 'should renew a license that has recently expired' do
      expect(BroadcastEventService).to receive(:call) { expect(it).to include(event:) }.exactly(1).time

      freeze_time do
        license = create(:license, account:, policy:, expiry: 5.minutes.ago)

        worker.perform_async
        worker.drain

        expect(license.reload.expiry).to eq 5.minutes.ago + 1.month
      end
    end

    it 'should renew a license according to the renewal basis' do
      expect(BroadcastEventService).to receive(:call) { expect(it).to include(event:) }.exactly(1).time

      policy.update!(renewal_basis: 'FROM_NOW')

      freeze_time do
        license = create(:license, account:, policy:, expiry: 5.minutes.ago)

        worker.perform_async
        worker.drain

        expect(license.reload.expiry).to eq 1.month.from_now
      end
    end

    it 'should renew multiple licenses' do
      expect(BroadcastEventService).to receive(:call) { expect(it).to include(event:) }.exactly(3).times

      create :license, account:, policy:, expiry: 9.minutes.from_now
      create :license, account:, policy:, expiry: Time.current
      create :license, account:, policy:, expiry: 11.hours.ago

      worker.perform_async
      worker.drain
    end

    it 'should not renew a license more than once' do
      expect(BroadcastEventService).to receive(:call) { expect(it).to include(event:) }.exactly(1).time

      create :license, account:, policy:, expiry: 5.minutes.ago

      2.times do
        worker.perform_async
        worker.drain
      end
    end

    it 'should not send a license.expired webhook event' do
      expect(BroadcastEventService).to_not receive(:call).with(hash_including(event: 'license.expired'))
      allow(BroadcastEventService).to receive(:call)

      license = create(:license, account:, policy:, expiry: 5.minutes.ago)

      worker.perform_async
      worker.drain

      expect(license.reload.last_expiration_event_sent_at).to be nil
    end

    it 'should not renew a license that is not yet due' do
      expect(BroadcastEventService).to_not receive(:call).with(hash_including(event:))
      allow(BroadcastEventService).to receive(:call)

      license = create(:license, account:, policy:, expiry: 1.hour.from_now)

      expect { worker.perform_async; worker.drain }.to_not change { license.reload.expiry }
    end

    it 'should not renew a license that expired long ago' do
      expect(BroadcastEventService).to_not receive(:call)

      license = create(:license, account:, policy:, expiry: 1.day.ago)

      expect { worker.perform_async; worker.drain }.to_not change { license.reload.expiry }
    end

    it 'should not renew a suspended license' do
      expect(BroadcastEventService).to receive(:call) { expect(it).to include(event: 'license.expired') }.exactly(1).time

      license = create(:license, account:, policy:, expiry: 5.minutes.ago, suspended: true)

      expect { worker.perform_async; worker.drain }.to_not change { license.reload.expiry }
    end
  end

  context 'when there is a license that does not auto-renew' do
    it 'should not renew a license for a manual renewal policy' do
      expect(BroadcastEventService).to receive(:call) { expect(it).to include(event: 'license.expired') }.exactly(1).time

      policy  = create(:policy, account:, duration: 1.month, renewal_strategy: 'MANUAL_RENEW')
      license = create(:license, account:, policy:, expiry: 5.minutes.ago)

      expect { worker.perform_async; worker.drain }.to_not change { license.reload.expiry }
    end

    it 'should not renew a license for a no renewal policy' do
      expect(BroadcastEventService).to receive(:call) { expect(it).to include(event: 'license.expired') }.exactly(1).time

      policy  = create(:policy, account:, duration: 1.month, renewal_strategy: 'NO_RENEW')
      license = create(:license, account:, policy:, expiry: 5.minutes.ago)

      expect { worker.perform_async; worker.drain }.to_not change { license.reload.expiry }
    end
  end

  context 'when there is a license that is renewing soon' do
    let(:event)  { 'license.renewing-soon' }
    let(:policy) { create(:policy, account:, duration: 1.month, renewal_strategy: 'AUTO_RENEW') }

    it 'should send a license.renewing-soon webhook event' do
      expect(BroadcastEventService).to receive(:call) { expect(it).to include(event:) }.exactly(1).time

      create :license, account:, policy:, expiry: 2.days.from_now

      worker.perform_async
      worker.drain
    end

    it 'should send multiple license.renewing-soon webhook events' do
      expect(BroadcastEventService).to receive(:call) { expect(it).to include(event:) }.exactly(3).times

      create :license, account:, policy:, expiry: 2.days.from_now
      create :license, account:, policy:, expiry: 1.day.from_now
      create :license, account:, policy:, expiry: 1.hour.from_now
      create :license, account:, policy:, expiry: 5.days.from_now

      worker.perform_async
      worker.drain
    end

    it 'should limit license.renewing-soon webhook events to a daily interval' do
      expect(BroadcastEventService).to receive(:call) { expect(it).to include(event:) }.exactly(1).time

      create :license, account:, policy:, expiry: 2.days.from_now

      2.times do
        worker.perform_async
        worker.drain
      end
    end

    it 'should mark the license with the renewing soon event time' do
      license = create(:license, account:, policy:, expiry: 1.day.from_now)

      worker.perform_async
      worker.drain

      license.reload

      expect(license.last_renewing_soon_event_sent_at).not_to eq nil
      expect(license.last_expiring_soon_event_sent_at).to eq nil
    end

    it 'should send a license.expiring-soon webhook event for a suspended license' do
      expect(BroadcastEventService).to receive(:call) { expect(it).to include(event: 'license.expiring-soon') }.exactly(1).time

      create :license, account:, policy:, expiry: 2.days.from_now, suspended: true

      worker.perform_async
      worker.drain
    end
  end

  context 'when there is not a license that is renewing soon' do
    let(:event) { 'license.renewing-soon' }

    it 'should not send a license.renewing-soon webhook event for a manual renewal policy' do
      expect(BroadcastEventService).to receive(:call) { expect(it).to include(event: 'license.expiring-soon') }.exactly(1).time

      policy  = create(:policy, account:, duration: 1.month, renewal_strategy: 'MANUAL_RENEW')
      license = create(:license, account:, policy:, expiry: 2.days.from_now)

      worker.perform_async
      worker.drain

      expect(license.reload.last_renewing_soon_event_sent_at).to eq nil
    end
  end
end
