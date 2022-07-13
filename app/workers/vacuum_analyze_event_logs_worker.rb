class VacuumAnalyzeEventLogsWorker
  include Sidekiq::Worker
  include Sidekiq::Cronitor

  sidekiq_options queue: :cron, lock: :until_executed

  def perform
    conn = ActiveRecord::Base.connection

    conn.execute 'VACUUM ANALYZE event_logs'
  end
end
