class SerializableWebhookEvent < SerializableBase
  type "webhook-events"

  attribute :endpoint
  attribute :payload
  attribute :event
  attribute :status
  attribute :created do
    @object.created_at
  end
  attribute :updated do
    @object.updated_at
  end

  relationship :account do
    linkage always: true
    link :related do
      @url_helpers.v1_account_path @object.account
    end
  end

  link :self do
    @url_helpers.v1_account_webhook_event_path @object.account, @object
  end

  meta do
    { idempotencyToken: @object.idempotency_token }
  end
end
