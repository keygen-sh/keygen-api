# frozen_string_literal: true

class RecordMachineSparksWorker < BaseWorker
  sidekiq_options queue: :cron,
                  cronitor_enabled: true

  def perform
    Account.unordered.subscribed.find_each do |account|
      RecordMachineSparkWorker.perform_async(account.id)
    end
  end
end
