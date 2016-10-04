class WebhookEndpointSerializer < BaseSerializer
  type :webhook_endpoints

  attributes [
    :url,
    :created,
    :updated
  ]

  belongs_to :account
end
