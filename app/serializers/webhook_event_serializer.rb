class WebhookEventSerializer < BaseSerializer
  type :webhook_events

  attributes [
    :endpoint,
    :payload,
    :status
  ]

  belongs_to :account
end
