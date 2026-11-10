# frozen_string_literal: true

class LicenseRenewalsWorker < BaseWorker
  # Auto-renewals happen ahead of expiry so that a license's expiry does not
  # lapse between runs, tolerating a missed or delayed run of this worker.
  LEAD_TIME = 10.minutes

  sidekiq_options queue: :critical,
                  cronitor_enabled: true

  def perform
    # NOTE(ezekg) There's intentionally no lower bound on expiry, so that any
    #             overdue renewals are caught up, no matter how overdue.
    licenses = License.preload(:account, :policy)
                      .auto_renewing
                      .where(expiry: ..3.days.from_now)
                      .reorder(nil)

    licenses.unordered.find_each do |license|
      next if license.account.nil? || license.policy.nil?

      case
      when due?(license)
        next unless
          renew!(license)

        BroadcastEventService.call(
          event: "license.renewed",
          account: license.account,
          resource: license,
        )
      else
        # Limit number of events we dispatch for each license to a daily interval
        next if !license.last_renewing_soon_event_sent_at.nil? &&
                license.last_renewing_soon_event_sent_at > 24.hours.ago

        BroadcastEventService.call(
          event: "license.renewing-soon",
          account: license.account,
          resource: license,
        )

        license.touch(:last_renewing_soon_event_sent_at)
      end
    rescue => e
      # A failure to renew one license should not prevent renewing the rest
      Keygen.logger.exception(e)
    end
  end

  private

  def due?(license)
    license.auto_renewing? && license.expiry? && license.expiry <= LEAD_TIME.from_now
  end

  def renew!(license)
    license.with_lock do
      # Assert the license is still due after acquiring the lock, e.g. in
      # case it was renewed or suspended in the meantime.
      next false unless
        due?(license)

      # Catch up on any missed renewals so that the license is never left
      # with an expiry in the past, e.g. after a long queue delay.
      license.renew!(catch_up: true)
    end
  end
end
