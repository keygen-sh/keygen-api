class PruneMetricsWorker < BaseWorker
  BACKLOG_DAYS      = ENV.fetch('KEYGEN_PRUNE_METRIC_BACKLOG_DAYS') { 31 }.to_i
  STATEMENT_TIMEOUT = ENV.fetch('KEYGEN_PRUNE_STATEMENT_TIMEOUT')   { '1min' }
  EXEC_TIMEOUT      = ENV.fetch('KEYGEN_PRUNE_EXEC_TIMEOUT')        { 1.hour.to_i }.to_f
  BATCH_SIZE        = ENV.fetch('KEYGEN_PRUNE_BATCH_SIZE')          { 1_000 }.to_i
  BATCH_WAIT        = ENV.fetch('KEYGEN_PRUNE_BATCH_WAIT')          { 1 }.to_f

  sidekiq_options queue: :cron,
                  cronitor_disabled: false,
                  retry: 5

  def perform(ts = Time.current.iso8601)
    return if
      BACKLOG_DAYS <= 0 # never prune -- keep metrics backlog forever

    @cutoff_end_date   = BACKLOG_DAYS.days.ago.to_date
    @cutoff_start_date = Metric.unordered.where(created_date: ..cutoff_end_date).minimum(:created_date) || cutoff_end_date
    @start_time        = Time.parse(ts)

    Keygen.logger.info "[workers.prune-metrics] Starting: start=#{start_time} cutoff_start=#{cutoff_start_date} cutoff_end=#{cutoff_end_date}"

    catch :pause do
      (cutoff_start_date...cutoff_end_date).each do |date|
        accounts = Account.where_assoc_exists(:metrics,
          created_date: date,
        )

        Keygen.logger.info "[workers.prune-metrics] Pruning day: accounts=#{accounts.count} date=#{date}"

        accounts.unordered.find_each do |account|
          prune_metrics_for_date(account, date:)
        end

        Keygen.logger.info "[workers.prune-metrics] Pruned day: date=#{date}"
      end
    end

    Keygen.logger.info "[workers.prune-metrics] Done"
  end

  private

  attr_reader :cutoff_start_date,
              :cutoff_end_date,
              :start_time

  def prune_metrics_for_date(account, date:)
    metrics = account.metrics.unordered.where(created_date: date)

    total = metrics.count
    sum   = 0

    batches = (total / BATCH_SIZE) + 1
    batch   = 0

    Keygen.logger.info "[workers.prune-metrics] Pruning #{total} rows: account_id=#{account.id} date=#{date}"

    loop do
      unless within_execution_timeout?
        Keygen.logger.info "[workers.prune-metrics] Pausing: date=#{date} start=#{start_time} end=#{current_time}"

        throw :pause
      end

      count = metrics.statement_timeout(STATEMENT_TIMEOUT) do
        metrics.limit(BATCH_SIZE).delete_all
      end

      sum   += count
      batch += 1

      Keygen.logger.info "[workers.prune-metrics] Pruned #{count} rows: account_id=#{account.id} date=#{date} batch=#{batch}/#{batches} count=#{sum}/#{total}"

      sleep BATCH_WAIT

      break if count < BATCH_SIZE
    end

    Keygen.logger.info "[workers.prune-metrics] Pruning done: account_id=#{account.id} date=#{date} count=#{sum}/#{total}"
  end

  def current_time = Time.current

  def within_execution_timeout?
    current_time.before?(start_time + EXEC_TIMEOUT.seconds)
  end
end
