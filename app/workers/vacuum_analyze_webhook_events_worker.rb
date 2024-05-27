class VacuumAnalyzeWebhookEventsWorker < BaseWorker
  sidekiq_options queue: :cron,
                  cronitor_disabled: false

  def perform
    conn = ActiveRecord::Base.connection

    conn.execute 'VACUUM ANALYZE webhook_events'
  end
end
