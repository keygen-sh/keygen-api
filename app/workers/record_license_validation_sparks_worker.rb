# frozen_string_literal: true

class RecordLicenseValidationSparksWorker < BaseWorker
  sidekiq_options queue: :cron,
                  cronitor_enabled: true

  def perform
    Account.unordered.paid.find_each do |account|
      jitter = rand(0..6.hours) # prevent a thundering herd effect

      RecordLicenseValidationSparkWorker.perform_in(jitter, account.id)
    end
  end
end
