class PruneWebhookEventsWorker < BaseWorker
  BACKLOG_DAYS      = ENV.fetch('KEYGEN_PRUNE_WEBHOOK_BACKLOG_DAYS') { 30 }.to_i
  STATEMENT_TIMEOUT = ENV.fetch('KEYGEN_PRUNE_STATEMENT_TIMEOUT')    { '1min' }
  EXEC_TIMEOUT      = ENV.fetch('KEYGEN_PRUNE_EXEC_TIMEOUT')         { 1.hour.to_i }.to_f
  BATCH_SIZE        = ENV.fetch('KEYGEN_PRUNE_BATCH_SIZE')           { 1_000 }.to_i
  SLEEP_DURATION    = ENV.fetch('KEYGEN_PRUNE_SLEEP_DURATION')       { 1 }.to_f

  sidekiq_options queue: :cron,
                  cronitor_disabled: false,
                  retry: 5

  def perform(ts = Time.current.iso8601)
    return if
      BACKLOG_DAYS <= 0

    cutoff_end_date   = BACKLOG_DAYS.days.ago.to_date
    cutoff_start_date = WebhookEvent.where(created_at: ..cutoff_end_date.end_of_day).minimum('created_at::date') || cutoff_end_date
    start_time        = Time.parse(ts)

    Keygen.logger.info "[workers.prune-webhook-events] Starting: start=#{start_time} cutoff_start=#{cutoff_start_date} cutoff_end=#{cutoff_end_date}"

    (cutoff_start_date...cutoff_end_date).each do |date|
      accounts = Account.where_assoc_exists(:webhook_events,
        created_at: date.all_day,
      )

      Keygen.logger.info "[workers.prune-webhook-events] Pruning day: accounts=#{accounts.count} date=#{date}"

      accounts.unordered.find_each do |account|
        account_id = account.id
        events     = account.webhook_events.where(created_at: date.all_day)

        total = events.count
        sum   = 0

        batches = (total / BATCH_SIZE) + 1
        batch   = 0

        Keygen.logger.info "[workers.prune-webhook-events] Pruning #{total} rows: account_id=#{account_id} date=#{date} batches=#{batches}"

        loop do
          unless (t = Time.current).before?(start_time + EXEC_TIMEOUT.seconds)
            Keygen.logger.info "[workers.prune-webhook-events] Pausing: date=#{date} start=#{start_time} end=#{t}"

            return # we'll pick up on the next cron
          end

          count = events.statement_timeout(STATEMENT_TIMEOUT) do
            events.limit(BATCH_SIZE).delete_all
          end

          sum   += count
          batch += 1

          Keygen.logger.info "[workers.prune-webhook-events] Pruned #{sum}/#{total} rows: account_id=#{account_id} date=#{date} batch=#{batch}/#{batches}"

          sleep SLEEP_DURATION

          break if count < BATCH_SIZE
        end
      end

      Keygen.logger.info "[workers.prune-webhook-events] Done: date=#{date}"
    end
  end
end
