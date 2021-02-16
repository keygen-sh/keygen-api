class PruneMetricsWorker
  include Sidekiq::Worker

  sidekiq_options queue: :cron, unique: :until_executed

  def perform
    accounts = Account.joins(:metrics)
                      .where('metrics.created_at < ?', 90.days.ago)
                      .group('accounts.id')
                      .having('count(metrics.id) > 0')

    accounts.find_each do |account|
      loop do
        metrics = account.metrics
                         .where('created_at < ?', 90.days.ago)

        count = metrics.limit(1_000)
                       .delete_all

        break if count == 0
      end
    end
  end
end