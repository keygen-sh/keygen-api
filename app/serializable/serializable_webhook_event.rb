# frozen_string_literal: true

class SerializableWebhookEvent < SerializableBase
  type "webhook-events"

  attribute :endpoint
  attribute :payload
  attribute :event do
    # FIXME(ezekg) Backwards compat during deploy
    if @object.event_type.present?
      @object.event_type.event
    else
      @object.event
    end
  end
  attribute :status
  attribute :last_response_code
  attribute :last_response_body
  attribute :created do
    @object.created_at
  end
  attribute :updated do
    @object.updated_at
  end

  relationship :account do
    linkage always: true do
      { type: :accounts, id: @object.account_id }
    end
    link :related do
      @url_helpers.v1_account_path @object.account_id
    end
  end

  link :self do
    @url_helpers.v1_account_webhook_event_path @object.account_id, @object
  end

  meta do
    { idempotencyToken: @object.idempotency_token }
  end
end
