class CleanWebhooksWorker
  include Sidekiq::Worker
  include Sidetiq::Schedulable

  recurrence { monthly }

  def perform
    WebhookEvent.where("created_at < ?", 30.days.ago).destroy_all
  end
end
