class VacuumAnalyzeEventLogsWorker < BaseWorker
  STATEMENT_TIMEOUT = ENV.fetch('KEYGEN_VACUUM_STATEMENT_TIMEOUT') { '5min' }

  sidekiq_options queue: :cron,
                  cronitor_disabled: false

  def perform
    EventLog.statement_timeout(STATEMENT_TIMEOUT) do |conn|
      conn.execute 'VACUUM ANALYZE event_logs'
    end
  end
end
