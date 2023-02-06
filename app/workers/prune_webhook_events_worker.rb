class PruneWebhookEventsWorker < BaseWorker
  BATCH_SIZE     = ENV.fetch('PRUNE_BATCH_SIZE')     { 1_000 }.to_i
  SLEEP_DURATION = ENV.fetch('PRUNE_SLEEP_DURATION') { 1 }.to_f

  sidekiq_options queue: :cron,
                  lock: :until_executed,
                  cronitor_disabled: false

  def perform
    accounts = Account.joins(:webhook_events)
                      .where('webhook_events.created_at < ?', 30.days.ago)
                      .group('accounts.id')
                      .having('count(webhook_events.id) > 0')

    Keygen.logger.info "[workers.prune-webhook-events] Starting: accounts=#{accounts.count}"

    accounts.find_each do |account|
      account_id = account.id
      batch = 0

      Keygen.logger.info "[workers.prune-webhook-events] Pruning rows: account_id=#{account_id}"

      loop do
        events = account.webhook_events
                        .where('created_at < ?', 30.days.ago.beginning_of_day)

        batch += 1
        count = events.limit(BATCH_SIZE)
                      .delete_all

        Keygen.logger.info "[workers.prune-webhook-events] Pruned #{count} rows: account_id=#{account_id} batch=#{batch}"

        sleep SLEEP_DURATION

        break if count == 0
      end
    end

    Keygen.logger.info "[workers.prune-webhook-events] Done"
  end
end
