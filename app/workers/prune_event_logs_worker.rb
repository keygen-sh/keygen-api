class PruneEventLogsWorker < BaseWorker
  # Number of days to keep event logs in backlog. Set to 0 to keep
  # all event logs into perpetuity, i.e. to disable pruning.
  BACKLOG_DAYS = ENV.fetch('KEYGEN_PRUNE_EVENT_BACKLOG_DAYS') { 90 }.to_i

  # Number of days from backlog to target for pruning. The lower the
  # number, the better the performance. Use a higher number for e.g.
  # catching up going from a backlog of 90 days to 30. For normal
  # non-catch up workloads, this should be set to 1.
  TARGET_DAYS = ENV.fetch('KEYGEN_PRUNE_EVENT_TARGET_DAYS') { 1 }.to_i

  # The statement timeout for the delete query. This may need to be
  # raised depending on your data and batch size.
  STATEMENT_TIMEOUT = ENV.fetch('KEYGEN_PRUNE_STATEMENT_TIMEOUT') { '1min' }

  # Number of event logs to delete per batch. The larger the number,
  # the higher the impact on the database.
  BATCH_SIZE = ENV.fetch('KEYGEN_PRUNE_BATCH_SIZE') { 1_000 }.to_i

  # Number of seconds to wait in between batches.
  BATCH_WAIT = ENV.fetch('KEYGEN_PRUNE_BATCH_WAIT') { 1 }.to_f

  # High volume events elligible for pruning. Essentially, this
  # reduces the storage burden for noisy events. For example,
  # a license could be validated hundreds of times a day, or
  # a machine could send thousands of heartbeat pings every
  # day. This job prunes those superfluous event logs.
  HIGH_VOLUME_EVENTS = %w[
    license.validation.succeeded
    license.validation.failed
    machine.heartbeat.ping
    machine.heartbeat.pong
    process.heartbeat.ping
    process.heartbeat.pong
  ].freeze

  sidekiq_options queue: :cron,
                  cronitor_disabled: false

  def perform
    return if
      BACKLOG_DAYS <= 0

    end_date   = BACKLOG_DAYS.days.ago.beginning_of_day
    start_date = (end_date - TARGET_DAYS.day).beginning_of_day

    # FIXME(ezekg) Update this to use created_date after we've backfilled old logs
    accounts = Account.where(<<~SQL.squish, start_date:, end_date:)
      EXISTS (
        SELECT
          1
        FROM
          "event_logs"
        WHERE
          "event_logs"."account_id"  = "accounts"."id" AND
          "event_logs"."created_date" >= :start_date     AND
          "event_logs"."created_date" <  :end_date
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
                                       .where('created_date >= ?', start_date)
                                       .where('created_date < ?', end_date)

        # Keep the latest log per-resource for each day and event type (i.e. discard duplicates)
        kept_logs = event_logs.distinct_on(:resource_id, :resource_type, :event_type_id, :created_date)
                              .reorder(:resource_id, :resource_type, :event_type_id,
                                created_date: :desc,
                              )
                              .select(:id)

        batch += 1
        count = event_logs.statement_timeout(STATEMENT_TIMEOUT) do
          event_logs.limit(BATCH_SIZE)
                    .delete_by(
                      "id NOT IN (#{kept_logs.to_sql})",
                    )
        end

        Keygen.logger.info "[workers.prune-event-logs] Pruned #{count} rows: account_id=#{account_id} batch=#{batch}"

        sleep BATCH_WAIT

        break if count < BATCH_SIZE
      end
    end

    Keygen.logger.info "[workers.prune-event-logs] Done"
  end
end
