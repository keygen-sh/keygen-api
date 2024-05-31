class PruneRequestLogsWorker < BaseWorker
  BACKLOG_DAYS      = ENV.fetch('KEYGEN_PRUNE_REQUEST_BACKLOG_DAYS') { 31 }.to_i
  TARGET_DAYS       = ENV.fetch('KEYGEN_PRUNE_REQUEST_TARGET_DAYS')  { 1 }.to_i
  STATEMENT_TIMEOUT = ENV.fetch('KEYGEN_PRUNE_STATEMENT_TIMEOUT')    { '1min' }
  BATCH_SIZE        = ENV.fetch('KEYGEN_PRUNE_BATCH_SIZE')           { 1_000 }.to_i
  BATCH_WAIT        = ENV.fetch('KEYGEN_PRUNE_BATCH_WAIT')           { 1 }.to_f

  sidekiq_options queue: :cron,
                  cronitor_disabled: false

  def perform
    return if
      BACKLOG_DAYS <= 0 # never prune -- keep request backlog forever

    target_date = BACKLOG_DAYS.days.ago.to_date
    target_date = (target_date - TARGET_DAYS.days)..target_date if TARGET_DAYS > 1

    accounts = Account.where_assoc_exists(:request_logs,
      created_date: target_date,
    )

    Keygen.logger.info "[workers.prune-request-logs] Starting: accounts=#{accounts.count} date=#{target_date}"

    accounts.find_each do |account|
      account_id   = account.id
      request_logs = account.request_logs.where(created_date: target_date)

      total = request_logs.count
      sum   = 0

      batches = (total / BATCH_SIZE) + 1
      batch   = 0

      Keygen.logger.info "[workers.prune-request-logs] Pruning #{total} rows: account_id=#{account_id} batches=#{batches}"

      loop do
        count = request_logs.statement_timeout(STATEMENT_TIMEOUT) do
          account.request_logs.where(id: request_logs.limit(BATCH_SIZE).reorder(nil).ids)
                              .delete_all
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
