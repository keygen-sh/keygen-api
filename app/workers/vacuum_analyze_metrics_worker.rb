class VacuumAnalyzeMetricsWorker
  include Sidekiq::Worker

  sidekiq_options queue: :cron, lock: :until_executed

  def perform
    conn = ActiveRecord::Base.connection

    conn.execute 'VACUUM ANALYZE metrics'
  end
end