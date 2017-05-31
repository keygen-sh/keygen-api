class LicenseOverdueCheckInsWorker
  include Sidekiq::Worker

  sidekiq_options queue: :cron

  def perform
    License.joins(:policy).where(policies: { require_check_in: true }).find_each do |license|
      next if license.expired?

      case
      when license.check_in_overdue?
        # Limit number of events we dispatch for each license to a daily interval
        next if !license.last_check_in_event_sent_at.nil? &&
                license.last_check_in_event_sent_at > 1.day.ago
        # Stop sending events after 7 days have passed
        next if !license.next_check_in_at.nil? &&
                license.next_check_in_at < 7.days.ago

        CreateWebhookEventService.new(
          event: "license.check-in-overdue",
          account: license.account,
          resource: license
        ).execute

        license.update last_check_in_event_sent_at: Time.current
      when !license.next_check_in_at.nil? && license.next_check_in_at < 3.days.from_now
        # Limit number of events we dispatch for each license to a daily interval
        next if !license.last_check_in_event_sent_at.nil? &&
                license.last_check_in_event_sent_at > 1.day.ago

        CreateWebhookEventService.new(
          event: "license.check-in-required-soon",
          account: license.account,
          resource: license
        ).execute

        license.update last_check_in_event_sent_at: Time.current
      end
    end
  end
end
