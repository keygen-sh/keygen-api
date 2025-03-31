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

  # High volume events eligible for pruning. Essentially, this
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
      BACKLOG_DAYS <= 0 # never prune -- keep event backlog forever

    target_date = BACKLOG_DAYS.days.ago.to_date
    target_date = (target_date - TARGET_DAYS.days)..target_date if TARGET_DAYS > 1

    # we only want to prune certain high-volume event logs for ent accounts
    event_type_ids = EventType.where(event: HIGH_VOLUME_EVENTS)
                              .pluck(:id)

    accounts = Account.where_assoc_exists(:event_logs,
      created_date: target_date,
    )

    Keygen.logger.info "[workers.prune-event-logs] Starting: accounts=#{accounts.count} date=#{target_date}"

    accounts.find_each do |account|
      account_id = account.id
      event_logs = account.event_logs.where(created_date: target_date)

      total = event_logs.count
      sum   = 0

      batches = (total / BATCH_SIZE) + 1
      batch   = 0

      Keygen.logger.info "[workers.prune-event-logs] Pruning #{total} rows: account_id=#{account_id} batches=#{batches}"

      loop do
        count = event_logs.statement_timeout(STATEMENT_TIMEOUT) do
          prune = account.event_logs.where(id: event_logs.limit(BATCH_SIZE).reorder(nil).ids)

          # for ent accounts, we keep event backlog into perpetuity except for dup high-volume events.
          # for std accounts, we prune everything outside the event backlog retention period.
          if account.ent?
            prune = prune.where(event_type_id: event_type_ids)

            # for high-volume events, we keep one event per-day per-event per-resource since some of these can
            # be very high-volume, e.g. thousands and thousands of validations and heartbeats per-day.
            keep = prune.distinct_on(:resource_id, :resource_type, :event_type_id, :created_date)
                        .reorder(:resource_id, :resource_type, :event_type_id,
                          created_date: :desc,
                        )
                        .select(
                          :id,
                        )

            # FIXME(ezekg) would be better to somehow rollup this data vs deduping
            prune.delete_by("id NOT IN (#{keep.to_sql})")
          else
            prune.delete_all
          end
        end

        sum   += count
        batch += 1

        Keygen.logger.info "[workers.prune-event-logs] Pruned #{sum}/#{total} rows: account_id=#{account_id} batch=#{batch}/#{batches}"

        sleep BATCH_WAIT

        break if count < BATCH_SIZE
      end
    end

    Keygen.logger.info "[workers.prune-event-logs] Done"
  end
end
