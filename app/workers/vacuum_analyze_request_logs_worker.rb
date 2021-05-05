class VacuumAnalyzeRequestLogsWorker
  include Sidekiq::Worker
  include Sidekiq::Cronitor

  sidekiq_options queue: :cron, lock: :until_executed

  def perform
    conn = ActiveRecord::Base.connection

    conn.execute 'VACUUM ANALYZE request_logs'
  end
end