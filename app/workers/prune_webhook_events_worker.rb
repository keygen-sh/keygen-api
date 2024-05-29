class PruneWebhookEventsWorker < BaseWorker
  BACKLOG_DAYS      = ENV.fetch('KEYGEN_PRUNE_WEBHOOK_BACKLOG_DAYS') { 30 }.to_i
  TARGET_DAYS       = ENV.fetch('KEYGEN_PRUNE_WEBHOOK_TARGET_DAYS')  { 1 }.to_i
  STATEMENT_TIMEOUT = ENV.fetch('KEYGEN_PRUNE_STATEMENT_TIMEOUT')    { '1min' }
  BATCH_SIZE        = ENV.fetch('KEYGEN_PRUNE_BATCH_SIZE')           { 1_000 }.to_i
  SLEEP_DURATION    = ENV.fetch('KEYGEN_PRUNE_SLEEP_DURATION')       { 1 }.to_f

  sidekiq_options queue: :cron,
                  cronitor_disabled: false

  def perform
    return if
      BACKLOG_DAYS <= 0

    end_date   = BACKLOG_DAYS.days.ago.beginning_of_day
    start_date = (end_date - TARGET_DAYS.day).beginning_of_day

    accounts = Account.where(<<~SQL.squish, start_date:, end_date:)
      EXISTS (
        SELECT
          1
        FROM
          "webhook_events"
        WHERE
          "webhook_events"."account_id"  = "accounts"."id" AND
          "webhook_events"."created_at" >= :start_date     AND
          "webhook_events"."created_at" <  :end_date
        LIMIT
          1
      )
    SQL

    Keygen.logger.info "[workers.prune-webhook-events] Starting: accounts=#{accounts.count}"

    accounts.find_each do |account|
      account_id = account.id
      batch = 0

      Keygen.logger.info "[workers.prune-webhook-events] Pruning rows: account_id=#{account_id}"

      loop do
        events = account.webhook_events.where('created_at >= ?', start_date)
                                       .where('created_at < ?', end_date)

        batch += 1
        count = events.statement_timeout(STATEMENT_TIMEOUT) do
          events.limit(BATCH_SIZE).delete_all
        end

        Keygen.logger.info "[workers.prune-webhook-events] Pruned #{count} rows: account_id=#{account_id} batch=#{batch}"

        sleep SLEEP_DURATION

        break if count < BATCH_SIZE
      end
    end

    Keygen.logger.info "[workers.prune-webhook-events] Done"
  end
end
