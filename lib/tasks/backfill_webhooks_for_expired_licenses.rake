# frozen_string_literal: true

desc 'backfill webhook events for expired licenses (missed due to blocked worker)'
task backfill_webhooks_for_expired_licenses: :environment do
  licenses = License.preload(:account, :policy)
                    .reorder(nil)
                    .where.not(expiry: nil)
                    .where(expiry: [2.weeks.ago...12.hours.ago], last_expiration_event_sent_at: nil)

  licenses.find_each do |license|
    next if license.account.nil? || license.policy.nil?

    case
    when license.expired?
      next unless license.last_expiration_event_sent_at.nil?

      CreateWebhookEventService.call(
        event: "license.expired",
        account: license.account,
        resource: license
      )

      license.update last_expiration_event_sent_at: Time.current
    end
  end
end
