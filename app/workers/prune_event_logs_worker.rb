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
    license.usage.incremented
    license.usage.decremented
    machine.heartbeat.ping
    machine.heartbeat.pong
    process.heartbeat.ping
    process.heartbeat.pong
    artifact.downloaded
    release.downloaded
  ].freeze

  sidekiq_options queue: :cron,
                  cronitor_disabled: false,
                  retry: 5

  def perform(ts = Time.current.iso8601)
    return if
      BACKLOG_DAYS <= 0 # never prune -- keep event backlog forever

    @hi_vol_event_type_ids = EventType.where(event: HIGH_VOLUME_EVENTS).ids
    @cutoff_end_date       = BACKLOG_DAYS.days.ago.to_date
    @cutoff_start_date     = EventLog.where(created_date: ..cutoff_end_date).minimum(:created_date) || cutoff_end_date
    @start_time            = Time.parse(ts)

    Keygen.logger.info "[workers.prune-event-logs] Starting: start=#{start_time} cutoff_start=#{cutoff_start_date} cutoff_end=#{cutoff_end_date}"

    (cutoff_start_date...cutoff_end_date).each do |date|
      accounts = Account.preload(:plan).where_assoc_exists(:event_logs, created_date: date)

      Keygen.logger.info "[workers.prune-event-logs] Pruning period: accounts=#{accounts.count} date=#{date}"

      catch :pause do
        accounts.unordered.find_each do |account|
          prune_event_logs_if_needed(account, date:)
        end
      end

      Keygen.logger.info "[workers.prune-event-logs] Done: date=#{date}"
    end
  end

  private

  attr_reader :hi_vol_event_type_ids,
              :cutoff_start_date,
              :cutoff_end_date,
              :start_time

  def prune_event_logs_if_needed(account, date:)
    if within_retention_period?(account, date:)
      dedup_hi_vol_event_logs_for_date(account, date:)
    else
      prune_event_logs_for_date(account, date:)
    end
  end

  def dedup_hi_vol_event_logs_for_date(account, date:)
    hi_vol_event_logs = account.event_logs.where(
      event_type_id: hi_vol_event_type_ids,
      created_date: date,
    )

    # partition and rank to dedup high volume events within retention period
    ranked_event_logs = hi_vol_event_logs.reorder(nil).select(<<~SQL.squish)
      event_logs.id,
      event_logs.created_at,
      ROW_NUMBER() OVER (
        PARTITION BY
          event_logs.account_id,
          event_logs.event_type_id,
          event_logs.resource_id,
          event_logs.resource_type,
          event_logs.created_date
        ORDER BY
          event_logs.created_at DESC
      ) AS rank
    SQL

    # select all rows except the top of the partition to delete i.e. to dedup events per-date/event/resource
    selected_event_logs = EventLog.from("(#{ranked_event_logs.to_sql}) AS ranked")
                                  .where('ranked.rank > 1')
                                  .reorder(
                                    'ranked.created_at ASC',
                                  )

    total = selected_event_logs.count
    sum   = 0

    batches = (total / BATCH_SIZE) + 1
    batch   = 0

    Keygen.logger.info "[workers.prune-event-logs] Deduping #{total} rows: account_id=#{account.id} date=#{date}"

    loop do
      unless within_execution_timeout?
        Keygen.logger.info "[workers.prune-event-logs] Pausing dedup: date=#{date} start=#{start_time} end=#{current_time}"

        throw :pause
      end

      count = EventLog.statement_timeout(STATEMENT_TIMEOUT) do
        selected_ids = selected_event_logs.limit(BATCH_SIZE).select(:id)

        EventLog.where(id: selected_ids).delete_all
      end

      break if
        count.zero?

      sum   += count
      batch += 1

      Keygen.logger.info "[workers.prune-event-logs] Deduped #{count} rows: account_id=#{account.id} date=#{date} batch=#{batch}/#{batches} progress=#{sum}/#{total}"

      sleep BATCH_WAIT
    end

    Keygen.logger.info "[workers.prune-event-logs] Deduping done: account_id=#{account.id} date=#{date} progress=#{sum}/#{total}"
  end

  def prune_event_logs_for_date(account, date:)
    event_logs = account.event_logs.where(created_date: date)

    total = event_logs.count
    sum   = 0

    batches = (total / BATCH_SIZE) + 1
    batch   = 0

    Keygen.logger.info "[workers.prune-event-logs] Pruning #{total} rows: account_id=#{account.id} date=#{date}"

    loop do
      unless within_execution_timeout?
        Keygen.logger.info "[workers.prune-event-logs] Pausing: date=#{date} start=#{start_time} end=#{current_time}"

        throw :pause
      end

      count = event_logs.statement_timeout(STATEMENT_TIMEOUT) do
        event_logs.limit(BATCH_SIZE).delete_all
      end

      break if
        count.zero?

      sum   += count
      batch += 1

      Keygen.logger.info "[workers.prune-event-logs] Pruned #{count} rows: account_id=#{account.id} date=#{date} batch=#{batch}/#{batches} count=#{sum}/#{total}"

      sleep BATCH_WAIT
    end

    Keygen.logger.info "[workers.prune-event-logs] Pruning done: account_id=#{account.id} date=#{date} count=#{sum}/#{total}"
  end

  def current_time = Time.current

  def within_execution_timeout?
    current_time.before?(start_time + EXEC_TIMEOUT.seconds)
  end

  def within_retention_period?(account, date:)
    plan = account.plan

    return false unless
      plan.present? && plan.event_log_retention_duration?

    cutoff_date = plan.event_log_retention_duration.seconds
                                                   .ago
                                                   .to_date

    date >= cutoff_date
  end
end
