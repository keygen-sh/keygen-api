# frozen_string_literal: true

class WebhookEventSerializer < BaseSerializer
  type 'webhook-events'

  attribute :endpoint
  attribute :payload do
    if @object.respond_to?(:payload)
      @object.payload
    else
      nil
    end
  end
  attribute :event do
    @object.event_type.event
  end
  attribute :status
  attribute :last_response_code
  attribute :last_response_body do
    if @object.respond_to?(:last_response_body)
      @object.last_response_body
    else
      nil
    end
  end
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

  ee do
    relationship :environment do
      linkage always: true do
        if @object.environment_id.present?
          { type: :environments, id: @object.environment_id }
        else
          nil
        end
      end
      link :related do
        if @object.environment_id.present?
          @url_helpers.v1_account_environment_path @object.account_id, @object.environment_id
        else
          nil
        end
      end
    end
  end

  link :self do
    @url_helpers.v1_account_webhook_event_path @object.account_id, @object
  end

  meta do
    { idempotencyToken: @object.idempotency_token }
  end
end
