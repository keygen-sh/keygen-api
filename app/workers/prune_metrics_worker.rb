class PruneMetricsWorker < BaseWorker
  BACKLOG_DAYS      = ENV.fetch('KEYGEN_PRUNE_METRIC_BACKLOG_DAYS') { 31 }.to_i
  STATEMENT_TIMEOUT = ENV.fetch('KEYGEN_PRUNE_STATEMENT_TIMEOUT')   { '1min' }
  EXEC_TIMEOUT      = ENV.fetch('KEYGEN_PRUNE_EXEC_TIMEOUT')        { 1.hour.to_i }.to_f
  BATCH_SIZE        = ENV.fetch('KEYGEN_PRUNE_BATCH_SIZE')          { 1_000 }.to_i
  BATCH_WAIT        = ENV.fetch('KEYGEN_PRUNE_BATCH_WAIT')          { 1 }.to_f

  sidekiq_options queue: :cron,
                  cronitor_disabled: false,
                  retry: 5

  def perform(ts = Time.current.iso8601)
    return if
      BACKLOG_DAYS <= 0 # never prune -- keep metrics backlog forever

    cutoff_date = BACKLOG_DAYS.days.ago.to_date
    start_time  = Time.parse(ts)

    accounts = Account.where_assoc_exists(:metrics,
      created_date: ...cutoff_date,
    )

    Keygen.logger.info "[workers.prune-metrics] Starting: accounts=#{accounts.count} start=#{start_time} cutoff=#{cutoff_date}"

    accounts.unordered.find_each do |account|
      account_id = account.id
      metrics    = account.metrics.where(created_date: ...cutoff_date)
                                  .reorder(created_date: :asc)

      total = metrics.count
      sum   = 0

      batches = (total / BATCH_SIZE) + 1
      batch   = 0

      Keygen.logger.info "[workers.prune-metrics] Pruning #{total} rows: account_id=#{account_id} batches=#{batches}"

      loop do
        unless (t = Time.current).before?(start_time + EXEC_TIMEOUT.seconds)
          Keygen.logger.info "[workers.prune-metrics] Pausing: start=#{start_time} end=#{t}"

          return # we'll pick up on the next cron
        end

        count = metrics.statement_timeout(STATEMENT_TIMEOUT) do
          account.metrics.where(id: metrics.limit(BATCH_SIZE).ids)
                         .delete_all
        end

        sum   += count
        batch += 1

        Keygen.logger.info "[workers.prune-metrics] Pruned #{sum}/#{total} rows: account_id=#{account_id} batch=#{batch}/#{batches}"

        sleep BATCH_WAIT

        break if count < BATCH_SIZE
      end
    end

    Keygen.logger.info "[workers.prune-metrics] Done"
  end
end
