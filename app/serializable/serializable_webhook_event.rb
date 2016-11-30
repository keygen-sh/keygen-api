class SerializableWebhookEvent < SerializableBase
  type 'webhook_events'

  attribute :payload
  attribute :jid
  attribute :created_at
  attribute :updated_at
  attribute :endpoint

  has_one :account
end
