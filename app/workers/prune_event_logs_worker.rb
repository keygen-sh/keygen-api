class PruneEventLogsWorker < BaseWorker
  BACKLOG_DAYS       = ENV.fetch('PRUNE_EVENT_BACKLOG_DAYS') { 90 }.to_i
  BATCH_SIZE         = ENV.fetch('PRUNE_BATCH_SIZE')         { 1_000 }.to_i
  SLEEP_DURATION     = ENV.fetch('PRUNE_SLEEP_DURATION')     { 1 }.to_f
  HIGH_VOLUME_EVENTS = %w[
    license.validation.succeeded
    license.validation.failed
    machine.heartbeat.ping
    machine.heartbeat.pong
    process.heartbeat.ping
    process.heartbeat.pong
  ].freeze

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
          "event_logs"
        WHERE
          "event_logs"."account_id" = "accounts"."id" AND
          "event_logs"."created_at" < ?
        LIMIT
          1
      )
    SQL

    Keygen.logger.info "[workers.prune-event-logs] Starting: accounts=#{accounts.count}"

    # We only want to prune certain high-volume event logs
    event_type_ids = EventType.where(event: HIGH_VOLUME_EVENTS)
                              .pluck(:id)

    accounts.find_each do |account|
      account_id = account.id
      batch      = 0

      Keygen.logger.info "[workers.prune-event-logs] Pruning rows: account_id=#{account_id}"

      loop do
        event_logs = account.event_logs
                            .where('created_at < ?', BACKLOG_DAYS.days.ago.beginning_of_day)
                            .where(event_type_id: event_type_ids)

        batch += 1
        count = event_logs.limit(BATCH_SIZE)
                          .delete_all

        Keygen.logger.info "[workers.prune-event-logs] Pruned #{count} rows: account_id=#{account_id} batch=#{batch}"

        sleep SLEEP_DURATION

        break if count == 0
      end
    end

    Keygen.logger.info "[workers.prune-event-logs] Done"
  end
end
