class WebhookSerializer < BaseSerializer
  type :webhooks

  attributes [
    :endpoint,
    :created,
    :updated
  ]

  belongs_to :account
end
