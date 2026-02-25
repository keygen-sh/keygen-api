# frozen_string_literal: true

class RecordUserSparkWorker < BaseWorker
  sidekiq_options queue: :cron,
                  cronitor_enabled: true

  def perform(account_id)
    account = Account.find(account_id)
    now     = Time.current
    today   = now.to_date

    rows = [nil, *account.environments].map do |environment|
      gauge = Analytics::Gauge.new(:users, account:, environment:)

      {
        account_id: account.id,
        environment_id: environment&.id,
        count: gauge.count,
        created_date: today,
        created_at: now,
      }
    end

    UserSpark.insert_all!(rows)
  end
end
