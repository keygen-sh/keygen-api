class LicenseExpirationsWorker
  include Sidekiq::Worker

  sidekiq_options queue: :cron, unique: :until_executed

  def perform
    License.where.not(expiry: nil).find_each do |license|
      case
      when license.expired?
        # Limit number of events we dispatch for each license to a daily interval
        next if !license.last_expiration_event_sent_at.nil? &&
                license.last_expiration_event_sent_at > 1.day.ago
        # Stop sending events after 7 days have passed
        next if license.expiry < 7.days.ago

        CreateWebhookEventService.new(
          event: "license.expired",
          account: license.account,
          resource: license
        ).execute

        license.update last_expiration_event_sent_at: Time.current
      when license.expiry < 3.days.from_now
        # Limit number of events we dispatch for each license to a daily interval
        next if !license.last_expiration_event_sent_at.nil? &&
                license.last_expiration_event_sent_at > 1.day.ago

        CreateWebhookEventService.new(
          event: "license.expiring-soon",
          account: license.account,
          resource: license
        ).execute

        license.update last_expiration_event_sent_at: Time.current
      end
    end
  end
end
