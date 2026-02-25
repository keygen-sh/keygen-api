# frozen_string_literal: true

class RecordLicenseSparksWorker < BaseWorker
  sidekiq_options queue: :cron,
                  cronitor_enabled: true

  def perform
    Account.unordered.subscribed.find_each do |account|
      jitter = rand(0..30.minutes)

      RecordLicenseSparkWorker.perform_in(jitter, account.id)
    end
  end
end
