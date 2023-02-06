class VacuumAnalyzeEventLogsWorker < BaseWorker
  sidekiq_options queue: :cron,
                  lock: :until_executed,
                  cronitor_disabled: false

  def perform
    conn = ActiveRecord::Base.connection

    conn.execute 'VACUUM ANALYZE event_logs'
  end
end
