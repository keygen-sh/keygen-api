class VacuumAnalyzeWebhookEventsWorker
  include Sidekiq::Worker

  sidekiq_options queue: :cron, unique: :until_executed

  def perform
    conn = ActiveRecord::Base.connection

    conn.execute 'VACUUM ANALYZE webhook_events'
  end
end