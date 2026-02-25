# frozen_string_literal: true

class RecordActiveLicensedUserSparksWorker < BaseWorker
  sidekiq_options queue: :cron,
                  cronitor_enabled: true

  def perform
    Account.unordered.subscribed.find_each do |account|
      RecordActiveLicensedUserSparkWorker.perform_async(account.id)
    end
  end
end
