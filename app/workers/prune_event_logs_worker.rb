class PruneEventLogsWorker < BaseWorker
  BACKLOG_DAYS       = ENV.fetch('KEYGEN_PRUNE_EVENT_BACKLOG_DAYS') { 90 }.to_i
  BATCH_SIZE         = ENV.fetch('KEYGEN_PRUNE_BATCH_SIZE')         { 1_000 }.to_i
  BATCH_WAIT         = ENV.fetch('KEYGEN_PRUNE_BATCH_WAIT')         { 1 }.to_f
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

    end_date   = BACKLOG_DAYS.days.ago.beginning_of_day
    start_date = (end_date - 1.day).beginning_of_day

    # FIXME(ezekg) Update this to use created_date after we've backfilled old logs
    accounts = Account.where(<<~SQL.squish, start_date:, end_date:)
      EXISTS (
        SELECT
          1
        FROM
          "event_logs"
        WHERE
          "event_logs"."account_id"  = "accounts"."id" AND
          "event_logs"."created_at" >= :start_date     AND
          "event_logs"."created_at" <  :end_date
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
        # FIXME(ezekg) Update this to use created_date after we've backfilled old logs
        event_logs = account.event_logs.where(event_type_id: event_type_ids)
                                       .where('created_at >= ?', start_date)
                                       .where('created_at < ?', end_date)

        # Keep the latest log per-resource for each day and event type (i.e. discard duplicates)
        kept_logs = event_logs.distinct_on(:resource_id, :resource_type, :event_type_id, :created_date)
                              .reorder(:resource_id, :resource_type, :event_type_id,
                                created_date: :desc,
                              )
                              .select(:id)

        batch += 1
        count = event_logs.limit(BATCH_SIZE)
                          .delete_by(
                            "id NOT IN (#{kept_logs.to_sql})",
                          )

        Keygen.logger.info "[workers.prune-event-logs] Pruned #{count} rows: account_id=#{account_id} batch=#{batch}"

        sleep BATCH_WAIT

        break if count < BATCH_SIZE
      end
    end

    Keygen.logger.info "[workers.prune-event-logs] Done"
  end
end
