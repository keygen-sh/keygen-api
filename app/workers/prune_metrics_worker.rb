class PruneMetricsWorker
  include Sidekiq::Worker
  include Sidekiq::Cronitor

  sidekiq_options queue: :cron, lock: :until_executed

  def perform
    accounts = Account.joins(:metrics)
                      .where('metrics.created_at < ?', 60.days.ago)
                      .group('accounts.id')
                      .having('count(metrics.id) > 0')

    Keygen.logger.info "[worker.prune-metrics] Starting: accounts=#{accounts.count}"

    accounts.find_each do |account|
      account_id = account.id
      batch = 0

      Keygen.logger.info "[worker.prune-metrics] Pruning rows: account_id=#{account_id}"

      loop do
        metrics = account.metrics
                         .where('created_at < ?', 60.days.ago.beginning_of_day)

        batch += 1
        count = metrics.limit(1_000)
                       .delete_all

        Keygen.logger.info "[worker.prune-metrics] Pruned #{count} rows: account_id=#{account_id} batch=#{batch}"

        break if count == 0
      end
    end

    Keygen.logger.info "[worker.prune-metrics] Done"
  end
end