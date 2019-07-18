# frozen_string_literal: true

class SerializableWebhookEndpoint < SerializableBase
  type "webhook-endpoints"

  attribute :url
  attribute :subscriptions
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
    @url_helpers.v1_account_webhook_endpoint_path @object.account_id, @object
  end
end
