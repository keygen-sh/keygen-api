# frozen_string_literal: true

class LicenseExpirationsWorker < BaseWorker
  sidekiq_options queue: :critical,
                  lock: :until_executed, lock_ttl: 30.minutes, on_conflict: :raise,
                  cronitor_disabled: false

  def perform
    licenses = License.preload(:account, :policy)
                      .where.not(expiry: nil)
                      .where(expiry: 3.days.ago..3.days.from_now)
                      .reorder(nil)
                      .distinct

    licenses.find_each do |license|
      next if license.account.nil? || license.policy.nil?

      case
      when license.expired?
        # Limit number of events we dispatch for each license to a daily interval
        next if !license.last_expiration_event_sent_at.nil? &&
                license.last_expiration_event_sent_at > 24.hours.ago
        # Stop sending events after 12 hours have passed (allowing at max 2 events to be sent in total)
        next if license.expiry < 12.hours.ago

        BroadcastEventService.call(
          event: "license.expired",
          account: license.account,
          resource: license,
        )

        license.touch(:last_expiration_event_sent_at)
      when license.expiry < 3.days.from_now
        # Limit number of events we dispatch for each license to a daily interval
        next if !license.last_expiring_soon_event_sent_at.nil? &&
                license.last_expiring_soon_event_sent_at > 24.hours.ago

        BroadcastEventService.call(
          event: "license.expiring-soon",
          account: license.account,
          resource: license,
        )

        license.touch(:last_expiring_soon_event_sent_at)
      end
    end
  end
end
