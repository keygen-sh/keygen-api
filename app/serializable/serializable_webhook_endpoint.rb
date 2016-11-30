class SerializableWebhookEndpoint < SerializableBase
  type 'webhook_endpoints'

  attribute :url
  attribute :created_at
  attribute :updated_at

  has_one :account
end
