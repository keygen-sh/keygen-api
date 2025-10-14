class PruneEventLogsWorker < BaseWorker
  # Number of days to keep event logs in backlog. Set to 0 to keep
  # all event logs into perpetuity, i.e. to disable pruning.
  BACKLOG_DAYS = ENV.fetch('KEYGEN_PRUNE_EVENT_BACKLOG_DAYS') { 90 }.to_i

  # The statement timeout for the delete queries. This may need to be
  # raised depending on your data and batch size.
  STATEMENT_TIMEOUT = ENV.fetch('KEYGEN_PRUNE_STATEMENT_TIMEOUT') { '1min' }

  # The timeout for total job execution. This may need to be raised
  # depending on how much pruning needs to be done.
  EXEC_TIMEOUT = ENV.fetch('KEYGEN_PRUNE_EXEC_TIMEOUT') { 1.hour.to_i }.to_f

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
                  cronitor_disabled: false,
                  retry: 5

  def perform(ts = Time.current.iso8601)
    return if
      BACKLOG_DAYS <= 0 # never prune -- keep event backlog forever

    cutoff_date = BACKLOG_DAYS.days.ago.to_date
    start_time  = Time.parse(ts)

    # we only want to prune certain high-volume event logs for ent accounts
    hi_vol_event_type_ids = EventType.where(event: HIGH_VOLUME_EVENTS)
                                     .ids

    # FIXME(ezekg) should we iterate each day separately to improve performance?
    accounts = Account.preload(:plan).where_assoc_exists(:event_logs,
      created_date: ...cutoff_date,
    )

    Keygen.logger.info "[workers.prune-event-logs] Starting: accounts=#{accounts.count} start=#{start_time} cutoff=#{cutoff_date}"

    accounts.unordered.find_each do |account|
      account_id = account.id
      event_logs = account.event_logs.where(created_date: ...cutoff_date)
      plan       = account.plan

      total = event_logs.count
      sum   = 0

      batches = (total / BATCH_SIZE) + 1
      batch   = 0

      Keygen.logger.info "[workers.prune-event-logs] Pruning #{total} rows: account_id=#{account_id} batches=#{batches}"

      loop do
        unless (t = Time.current).before?(start_time + EXEC_TIMEOUT.seconds)
          Keygen.logger.info "[workers.prune-event-logs] Pausing: start=#{start_time} end=#{t}"

          return # we'll pick up on the next cron
        end

        count = event_logs.statement_timeout(STATEMENT_TIMEOUT) do
          prune = account.event_logs.where(id: event_logs.limit(BATCH_SIZE).reorder(nil).ids)

          # for ent accounts, we keep the event backlog for the retention period except dup high-volume events.
          # for std accounts, we prune everything in the event backlog.
          if plan.ent?
            hi_vol = prune.where(event_type_id: hi_vol_event_type_ids) # dedup even in retention period

            # apply the account's log retention policy if there is one
            if plan.event_log_retention_duration?
              retention_cutoff_date = plan.event_log_retention_duration.seconds.ago.to_date

              prune = prune.where(created_date: ...retention_cutoff_date)
            end

            # for high-volume events, we keep one event per-day per-event per-resource since some of these can
            # be very high-volume, e.g. thousands and thousands of validations and heartbeats per-day.
            keep = hi_vol.distinct_on(:resource_id, :resource_type, :event_type_id, :created_date)
                         .reorder(:resource_id, :resource_type, :event_type_id,
                           created_date: :desc,
                         )
                         .select(
                           :id,
                         )

            # FIXME(ezekg) would be better to somehow rollup this data vs deduping
            hi_vol.delete_by("id NOT IN (#{keep.to_sql})")
          end

          prune.delete_all
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
