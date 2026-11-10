# frozen_string_literal: true

class LicenseExpirationsWorker < BaseWorker
  # Auto-renewals happen slightly ahead of expiry, i.e. before the next run of
  # this worker, so that an auto-renewing license never lapses between runs.
  AUTO_RENEWAL_LEAD_TIME = 10.minutes

  # Stop attempting to auto-renew a license after it has been expired for this
  # long, e.g. so that changing a policy's renewal strategy to AUTO_RENEW does
  # not resurrect licenses that expired in the past.
  AUTO_RENEWAL_GRACE_PERIOD = 12.hours

  sidekiq_options queue: :critical,
                  cronitor_enabled: true

  def perform
    licenses = License.preload(:account, :policy)
                      .where.not(expiry: nil)
                      .where(expiry: 3.days.ago..3.days.from_now)
                      .reorder(nil)
                      .distinct

    licenses.unordered.find_each do |license|
      next if license.account.nil? || license.policy.nil?

      case
      when auto_renewable?(license)
        next unless
          auto_renew!(license)

        BroadcastEventService.call(
          event: "license.renewed",
          account: license.account,
          resource: license,
        )
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

  private

  # Whether or not the license will be auto-renewed, i.e. suspended licenses
  # are left to expire, and a policy without a duration cannot be renewed.
  def auto_renews?(license)
    license.auto_renew? && license.policy.duration? && !license.suspended?
  end

  # Whether or not the license is due to be auto-renewed right now.
  def auto_renewable?(license)
    auto_renews?(license) &&
      license.expiry <= AUTO_RENEWAL_LEAD_TIME.from_now &&
      license.expiry >= AUTO_RENEWAL_GRACE_PERIOD.ago
  end

  def auto_renew!(license)
    license.with_lock do
      # Assert the license is still due after acquiring the lock, e.g. in
      # case it was manually renewed or suspended in the meantime.
      next false unless
        auto_renewable?(license)

      license.renew!
    end
  rescue ActiveRecord::RecordInvalid => e
    Keygen.logger.warn { "[workers.license-expirations] auto-renewal failed: license_id=#{license.id} err=#{e.message}" }

    false
  end
end
