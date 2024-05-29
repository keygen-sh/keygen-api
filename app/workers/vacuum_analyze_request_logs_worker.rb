class VacuumAnalyzeRequestLogsWorker < BaseWorker
  STATEMENT_TIMEOUT = ENV.fetch('KEYGEN_VACUUM_STATEMENT_TIMEOUT') { '5min' }

  sidekiq_options queue: :cron,
                  cronitor_disabled: false

  def perform
    RequestLog.statement_timeout(STATEMENT_TIMEOUT) do |conn|
      conn.execute 'VACUUM ANALYZE request_logs'
    end
  end
end
