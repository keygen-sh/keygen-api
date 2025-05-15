# frozen_string_literal: true

class WebhookEndpointSerializer < BaseSerializer
  type 'webhook-endpoints'

  attribute :url
  attribute :subscriptions
  attribute :signature_algorithm
  attribute :api_version
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

  relationship :product do
    linkage always: true do
      if @object.product_id?
        { type: :products, id: @object.product_id }
      else
        nil
      end
    end
    link :related do
      if @object.product_id?
        @url_helpers.v1_account_product_path @object.account_id, @object.product_id
      else
        nil
      end
    end
  end

  link :self do
    @url_helpers.v1_account_webhook_endpoint_path @object.account_id, @object
  end
end
