# frozen_string_literal: true

class AccountSerializer < BaseSerializer
  type 'accounts'

  attribute :name
  attribute :slug
  attribute :api_version
  attribute :status
  attribute :protected
  attribute :created do
    @object.created_at
  end
  attribute :updated do
    @object.updated_at
  end

  if Keygen.multiplayer?
    relationship :billing, unless: -> { @object.billing.nil? } do
      linkage always: true do
        { type: :billings, id: @object.billing&.id }
      end
      link :related do
        @url_helpers.v1_account_billing_path @object if @object.billing.present?
      end
    end

    relationship :plan, unless: -> { @object.plan_id.nil? } do
      linkage always: true do
        { type: :plans, id: @object.plan_id }
      end
      link :related do
        @url_helpers.v1_account_plan_path @object if @object.plan_id.present?
      end
    end
  end

  relationship :webhook_endpoints do
    link :related do
      @url_helpers.v1_account_webhook_endpoints_path @object
    end
  end
  relationship :webhook_events do
    link :related do
      @url_helpers.v1_account_webhook_events_path @object
    end
  end
  relationship :products do
    link :related do
      @url_helpers.v1_account_products_path @object
    end
  end
  relationship :platforms do
    link :related do
      @url_helpers.v1_account_release_platforms_path @object
    end
  end
  relationship :arches do
    link :related do
      @url_helpers.v1_account_release_arches_path @object
    end
  end
  relationship :channels do
    link :related do
      @url_helpers.v1_account_release_channels_path @object
    end
  end
  relationship :releases do
    link :related do
      @url_helpers.v1_account_releases_path @object
    end
  end
  relationship :artifacts do
    link :related do
      @url_helpers.v1_account_release_artifacts_path @object
    end
  end
  relationship :policies do
    link :related do
      @url_helpers.v1_account_policies_path @object
    end
  end
  relationship :users do
    link :related do
      @url_helpers.v1_account_users_path @object
    end
  end
  relationship :keys do
    link :related do
      @url_helpers.v1_account_keys_path @object
    end
  end
  relationship :licenses do
    link :related do
      @url_helpers.v1_account_licenses_path @object
    end
  end
  relationship :machines do
    link :related do
      @url_helpers.v1_account_machines_path @object
    end
  end
  relationship :processes do
    link :related do
      @url_helpers.v1_account_machine_processes_path @object
    end
  end
  relationship :tokens do
    link :related do
      @url_helpers.v1_account_tokens_path @object
    end
  end

  link :self do
    @url_helpers.v1_account_path @object
  end

  meta do
    ed25519_key = Base64.strict_encode64(@object.ed25519_public_key)
    rsa2048_key = Base64.strict_encode64(@object.public_key)

    {
      publicKey: rsa2048_key,
      keys: {
        ed25519: ed25519_key,
        rsa2048: rsa2048_key,
      }
    }
  end
end
