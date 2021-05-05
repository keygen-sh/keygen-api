class PruneRequestLogsWorker
  include Sidekiq::Worker
  include Sidekiq::Cronitor

  sidekiq_options queue: :cron, lock: :until_executed

  def perform
    accounts = Account.joins(:request_logs)
                      .where('request_logs.created_at < ?', 30.days.ago)
                      .group('accounts.id')
                      .having('count(request_logs.id) > 0')

    accounts.find_each do |account|
      loop do
        logs = account.request_logs
                      .where('created_at < ?', 30.days.ago.beginning_of_day)

        count = logs.limit(1_000)
                    .delete_all

        break if count == 0
      end
    end
  end
end