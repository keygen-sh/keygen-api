# frozen_string_literal: true

class LicenseOverdueCheckInsWorker
  include Sidekiq::Worker

  sidekiq_options queue: :cron, unique: :until_executed

  def perform
    query = %[
      "policies"."require_check_in" = :require_check_in AND
      "policies"."check_in_interval_count" IS NOT NULL AND
      "policies"."check_in_interval" IS NOT NULL AND
      (
        "licenses"."last_check_in_at" + (
          "policies"."check_in_interval_count" || ' ' || "policies"."check_in_interval"
        )::interval
      ) BETWEEN
        :start_date AND
        :end_date
    ]

    License.preload(:account, :policy).joins(:policy).where(query, require_check_in: true, start_date: 3.days.ago, end_date: 3.days.from_now).find_each do |license|
      next if license.expired?

      case
      when license.check_in_overdue?
        # Limit number of events we dispatch for each license to a daily interval
        next if !license.last_check_in_event_sent_at.nil? &&
                license.last_check_in_event_sent_at > 24.hours.ago
        # Stop sending events after 12 hours have passed (allowing at max 2 events to be sent in total)
        next if !license.next_check_in_at.nil? &&
                license.next_check_in_at < 12.hours.ago

        CreateWebhookEventService.new(
          event: "license.check-in-overdue",
          account: license.account,
          resource: license
        ).execute

        license.update last_check_in_event_sent_at: Time.current
      when !license.next_check_in_at.nil? && license.next_check_in_at < 3.days.from_now
        # Limit number of events we dispatch for each license to a daily interval
        next if !license.last_check_in_soon_event_sent_at.nil? &&
                license.last_check_in_soon_event_sent_at > 24.hours.ago

        CreateWebhookEventService.new(
          event: "license.check-in-required-soon",
          account: license.account,
          resource: license
        ).execute

        license.update last_check_in_soon_event_sent_at: Time.current
      end
    end
  end
end
