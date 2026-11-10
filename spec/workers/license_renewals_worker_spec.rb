# frozen_string_literal: true

require 'rails_helper'
require 'spec_helper'

describe LicenseRenewalsWorker do
  let(:worker)  { LicenseRenewalsWorker }
  let(:account) { create(:account) }
  let(:policy)  { create(:policy, account:, duration: 1.month, renewal_strategy: 'AUTO_RENEW') }

  context 'when there is a license that is due for renewal' do
    let(:event) { 'license.renewed' }

    it 'should renew a license that is about to expire' do
      expect(BroadcastEventService).to receive(:call) { expect(it).to include(event:) }.exactly(1).time

      freeze_time do
        license = create(:license, account:, policy:, expiry: 5.minutes.from_now)

        worker.perform_async
        worker.drain

        expect(license.reload.expiry).to eq 5.minutes.from_now + 1.month
      end
    end

    it 'should renew a license that is overdue' do
      expect(BroadcastEventService).to receive(:call) { expect(it).to include(event:) }.exactly(1).time

      freeze_time do
        license = create(:license, account:, policy:, expiry: 5.minutes.ago)

        worker.perform_async
        worker.drain

        expect(license.reload.expiry).to eq 5.minutes.ago + 1.month
      end
    end

    it 'should catch up a license that is long overdue' do
      expect(BroadcastEventService).to receive(:call) { expect(it).to include(event:) }.exactly(1).time

      travel_to Time.utc(2026, 6, 15, 12) do
        license = create(:license, account:, policy:, expiry: Time.utc(2026, 1, 1))

        worker.perform_async
        worker.drain

        # Renewals keep to the original cycle, i.e. from expiry
        duration = ActiveSupport::Duration.build(policy.duration)
        expiry   = Time.utc(2026, 1, 1)
        expiry  += duration until expiry > Time.current

        expect(license.reload.expiry).to eq expiry
        expect(license.expiry).to be <= Time.current + 1.month
      end
    end

    it 'should renew a license according to the renewal basis' do
      expect(BroadcastEventService).to receive(:call) { expect(it).to include(event:) }.exactly(2).times

      freeze_time do
        from_now            = create(:policy, account:, duration: 1.month, renewal_strategy: 'AUTO_RENEW', renewal_basis: 'FROM_NOW')
        from_now_if_expired = create(:policy, account:, duration: 1.month, renewal_strategy: 'AUTO_RENEW', renewal_basis: 'FROM_NOW_IF_EXPIRED')

        a = create(:license, account:, policy: from_now, expiry: 3.days.ago)
        b = create(:license, account:, policy: from_now_if_expired, expiry: 3.days.ago)

        worker.perform_async
        worker.drain

        expect(a.reload.expiry).to eq 1.month.from_now
        expect(b.reload.expiry).to eq 1.month.from_now
      end
    end

    it 'should renew multiple licenses' do
      expect(BroadcastEventService).to receive(:call) { expect(it).to include(event:) }.exactly(3).times

      create :license, account:, policy:, expiry: 9.minutes.from_now
      create :license, account:, policy:, expiry: Time.current
      create :license, account:, policy:, expiry: 2.weeks.ago

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

    it 'should continue renewing when a renewal fails' do
      expect(BroadcastEventService).to receive(:call) { expect(it).to include(event:) }.exactly(2).times

      licenses = create_list(:license, 3, account:, policy:, expiry: 5.minutes.ago)
      failures = 0

      allow_any_instance_of(License).to receive(:renew!).and_wrap_original do |original, *args, **kwargs|
        raise ActiveRecord::StatementInvalid, 'failed' if (failures += 1) == 1

        original.call(*args, **kwargs)
      end

      worker.perform_async
      worker.drain

      expect(licenses.count { it.reload.expiry.future? }).to eq 2
    end
  end

  context 'when there is not a license that is due for renewal' do
    let(:event) { 'license.renewed' }

    it 'should not renew a license that is not yet due' do
      allow(BroadcastEventService).to receive(:call)
      expect(BroadcastEventService).to_not receive(:call).with(hash_including(event:))

      license = create(:license, account:, policy:, expiry: 1.hour.from_now)

      expect { worker.perform_async; worker.drain }.to_not change { license.reload.expiry }
    end

    it 'should not renew a suspended license' do
      expect(BroadcastEventService).to_not receive(:call)

      license = create(:license, account:, policy:, expiry: 5.minutes.ago, suspended: true)

      expect { worker.perform_async; worker.drain }.to_not change { license.reload.expiry }
    end

    it 'should not renew a canceled license' do
      expect(BroadcastEventService).to_not receive(:call)

      license = create(:license, account:, policy:, expiry: 5.minutes.from_now, canceled_at: 1.day.ago)

      expect { worker.perform_async; worker.drain }.to_not change { license.reload.expiry }
    end

    it 'should not renew a license without an expiry' do
      expect(BroadcastEventService).to_not receive(:call)

      license = create(:license, account:, policy:, expiry: nil)

      expect { worker.perform_async; worker.drain }.to_not change { license.reload.expiry }
    end

    it 'should not renew a license for an auto-renew policy without a duration' do
      expect(BroadcastEventService).to_not receive(:call)

      policy  = create(:policy, account:, duration: nil, renewal_strategy: 'AUTO_RENEW')
      license = create(:license, account:, policy:, expiry: 5.minutes.ago)

      expect { worker.perform_async; worker.drain }.to_not change { license.reload.expiry }
    end

    it 'should not renew a license for a manual renewal policy' do
      expect(BroadcastEventService).to_not receive(:call)

      policy  = create(:policy, account:, duration: 1.month, renewal_strategy: 'MANUAL_RENEW')
      license = create(:license, account:, policy:, expiry: 5.minutes.ago)

      expect { worker.perform_async; worker.drain }.to_not change { license.reload.expiry }
    end

    it 'should not renew a license for a no renewal policy' do
      expect(BroadcastEventService).to_not receive(:call)

      policy  = create(:policy, account:, duration: 1.month, renewal_strategy: 'NO_RENEW')
      license = create(:license, account:, policy:, expiry: 5.minutes.ago)

      expect { worker.perform_async; worker.drain }.to_not change { license.reload.expiry }
    end
  end

  context 'when there is a license that is renewing soon' do
    let(:event) { 'license.renewing-soon' }

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
  end

  context 'when there is not a license that is renewing soon' do
    it 'should not send a license.renewing-soon webhook event for a suspended license' do
      expect(BroadcastEventService).to_not receive(:call)

      create :license, account:, policy:, expiry: 2.days.from_now, suspended: true

      worker.perform_async
      worker.drain
    end

    it 'should not send a license.renewing-soon webhook event for a canceled license' do
      expect(BroadcastEventService).to_not receive(:call)

      create :license, account:, policy:, expiry: 2.days.from_now, canceled_at: 1.day.ago

      worker.perform_async
      worker.drain
    end

    it 'should not send a license.renewing-soon webhook event for a manual renewal policy' do
      expect(BroadcastEventService).to_not receive(:call)

      policy  = create(:policy, account:, duration: 1.month, renewal_strategy: 'MANUAL_RENEW')
      license = create(:license, account:, policy:, expiry: 2.days.from_now)

      worker.perform_async
      worker.drain

      expect(license.reload.last_renewing_soon_event_sent_at).to eq nil
    end
  end
end
