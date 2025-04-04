class PruneRequestLogsWorker < BaseWorker
  BACKLOG_DAYS      = ENV.fetch('KEYGEN_PRUNE_REQUEST_BACKLOG_DAYS') { 31 }.to_i
  STATEMENT_TIMEOUT = ENV.fetch('KEYGEN_PRUNE_STATEMENT_TIMEOUT')    { '1min' }
  EXEC_TIMEOUT      = ENV.fetch('KEYGEN_PRUNE_EXEC_TIMEOUT')         { 1.hour.to_i }.to_f
  BATCH_SIZE        = ENV.fetch('KEYGEN_PRUNE_BATCH_SIZE')           { 1_000 }.to_i
  BATCH_WAIT        = ENV.fetch('KEYGEN_PRUNE_BATCH_WAIT')           { 1 }.to_f

  sidekiq_options queue: :cron,
                  cronitor_disabled: false,
                  retry: 5

  def perform(ts = Time.current.iso8601)
    return if
      BACKLOG_DAYS <= 0 # never prune -- keep request backlog forever

    cutoff_date = BACKLOG_DAYS.days.ago.to_date
    start_time  = Time.parse(ts)

    accounts = Account.where_assoc_exists(:request_logs,
      created_date: ...cutoff_date,
    )

    Keygen.logger.info "[workers.prune-request-logs] Starting: accounts=#{accounts.count} start=#{start_time} cutoff=#{cutoff_date}"

    accounts.find_each do |account|
      account_id   = account.id
      request_logs = account.request_logs.where(created_date: ...cutoff_date)
      plan         = account.plan

      total = request_logs.count
      sum   = 0

      batches = (total / BATCH_SIZE) + 1
      batch   = 0

      Keygen.logger.info "[workers.prune-request-logs] Pruning #{total} rows: account_id=#{account_id} batches=#{batches}"

      loop do
        unless (t = Time.current).before?(start_time + EXEC_TIMEOUT.seconds)
          Keygen.logger.info "[workers.prune-request-logs] Pausing: start=#{start_time} end=#{t}"

          return # we'll pick up on the next cron
        end

        count = request_logs.statement_timeout(STATEMENT_TIMEOUT) do
          prune = account.request_logs.where(id: request_logs.limit(BATCH_SIZE).reorder(nil).ids)

          # apply the account's log retention policy if there is one
          if plan.ent? && plan.request_log_retention_duration?
            retention_cutoff_date = plan.request_log_retention_duration.seconds.ago.to_date

            prune = prune.where(created_date: ...retention_cutoff_date)
          end

          prune.delete_all
        end

        sum   += count
        batch += 1

        Keygen.logger.info "[workers.prune-request-logs] Pruned #{sum}/#{total} rows: account_id=#{account_id} batch=#{batch}/#{batches}"

        sleep BATCH_WAIT

        break if count < BATCH_SIZE
      end
    end

    Keygen.logger.info "[workers.prune-request-logs] Done"
  end
end
