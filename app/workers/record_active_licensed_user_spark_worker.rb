# frozen_string_literal: true

class RecordActiveLicensedUserSparkWorker < BaseWorker
  sidekiq_options queue: :cron,
                  cronitor_enabled: true

  def perform(account_id)
    account = Account.find(account_id)
    now     = Time.current
    today   = now.to_date
    gauge   = Analytics::Gauge.new(:active_licensed_users, account:)

    ActiveLicensedUserSpark.insert!({
      account_id: account.id,
      environment_id: nil,
      count: gauge.count,
      created_date: today,
      created_at: now,
    })
  end
end
