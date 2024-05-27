class VacuumAnalyzeEventLogsWorker < BaseWorker
  sidekiq_options queue: :cron,
                  cronitor_disabled: false

  def perform
    conn = ActiveRecord::Base.connection

    conn.execute 'VACUUM ANALYZE event_logs'
  end
end
