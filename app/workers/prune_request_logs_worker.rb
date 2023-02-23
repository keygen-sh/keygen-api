class PruneRequestLogsWorker < BaseWorker
  BACKLOG_DAYS       = ENV.fetch('PRUNE_REQUEST_BACKLOG_DAYS') { 30 }.to_i
  BATCH_SIZE         = ENV.fetch('PRUNE_BATCH_SIZE')           { 1_000 }.to_i
  SLEEP_DURATION     = ENV.fetch('PRUNE_SLEEP_DURATION')       { 1 }.to_f

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
          "request_logs"
        WHERE
          "request_logs"."account_id" = "accounts"."id" AND
          "request_logs"."created_at" < ?
        LIMIT
          1
      )
    SQL

    Keygen.logger.info "[workers.prune-request-logs] Starting: accounts=#{accounts.count}"

    accounts.find_each do |account|
      account_id = account.id
      batch      = 0

      Keygen.logger.info "[workers.prune-request-logs] Pruning rows: account_id=#{account_id}"

      loop do
        logs = account.request_logs
                      .where('created_at < ?', BACKLOG_DAYS.days.ago.beginning_of_day)

        batch += 1
        count = logs.limit(BATCH_SIZE)
                    .delete_all

        Keygen.logger.info "[workers.prune-request-logs] Pruned #{count} rows: account_id=#{account_id} batch=#{batch}"

        sleep SLEEP_DURATION

        break if count == 0
      end
    end

    Keygen.logger.info "[workers.prune-request-logs] Done"
  end
end
