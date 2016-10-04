class WebhookEventSerializer < BaseSerializer
  type :webhook_events

  attributes [
    :endpoint,
    :payload,
    :status
  ]

  belongs_to :account

  def status
    Sidekiq::Status.status object.jid rescue :unavailable
  end
end
