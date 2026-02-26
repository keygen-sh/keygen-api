# frozen_string_literal: true

class RecordActiveLicensedUserSparksWorker < BaseWorker
  sidekiq_options queue: :cron,
                  cronitor_enabled: true

  def perform
    Account.unordered.paid.find_each do |account|
      jitter = rand(0..30.minutes) # prevent a thundering herd effect

      RecordActiveLicensedUserSparkWorker.perform_in(jitter, account.id)
    end
  end
end
