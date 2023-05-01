class PruneMetricsWorker < BaseWorker
  BACKLOG_DAYS = ENV.fetch('KEYGEN_PRUNE_METRIC_BACKLOG_DAYS') { 30 }.to_i
  BATCH_SIZE   = ENV.fetch('KEYGEN_PRUNE_BATCH_SIZE')          { 1_000 }.to_i
  BATCH_WAIT   = ENV.fetch('KEYGEN_PRUNE_BATCH_WAIT')          { 1 }.to_f

  sidekiq_options queue: :cron,
                  lock: :until_executed,
                  cronitor_disabled: false

  def perform
    return if
      BACKLOG_DAYS <= 0

    accounts = Account.where(<<~SQL.squish, BACKLOG_DAYS.days.ago.beginning_of_day)
      EXISTS (
        SELECT
          1
        FROM
          "metrics"
        WHERE
          "metrics"."account_id" = "accounts"."id" AND
          "metrics"."created_at" < ?
        LIMIT
          1
      )
    SQL

    Keygen.logger.info "[workers.prune-metrics] Starting: accounts=#{accounts.count}"

    accounts.find_each do |account|
      account_id = account.id
      batch      = 0

      Keygen.logger.info "[workers.prune-metrics] Pruning rows: account_id=#{account_id}"

      loop do
        metrics = account.metrics
                         .where('created_at < ?', BACKLOG_DAYS.days.ago.beginning_of_day)

        batch += 1
        count = metrics.limit(BATCH_SIZE)
                       .delete_all

        Keygen.logger.info "[workers.prune-metrics] Pruned #{count} rows: account_id=#{account_id} batch=#{batch}"

        sleep BATCH_WAIT

        break if count < BATCH_SIZE
      end
    end

    Keygen.logger.info "[workers.prune-metrics] Done"
  end
end
