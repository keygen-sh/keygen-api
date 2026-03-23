# frozen_string_literal: true

class RecordEventSparksWorker < BaseWorker
  sidekiq_options queue: :cron,
                  cronitor_enabled: true

  def perform
    Account.unordered.paid.find_each do |account|
      jitter = rand(0..30.minutes) # prevent a thundering herd effect

      RecordEventSparkWorker.perform_in(jitter, account.id)
    end
  end
end
