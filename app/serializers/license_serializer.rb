# frozen_string_literal: true

class LicenseSerializer < BaseSerializer
  type :licenses

  attribute :name
  attribute :key, unless: -> { @object.legacy_encrypted? && @object.raw.nil? } do
    if @object.legacy_encrypted?
      @object.raw
    else
      @object.key
    end
  end
  attribute :expiry
  attribute :uses
  attribute :suspended
  attribute :scheme
  attribute :encrypted do
    @object.encrypted?
  end
  attribute :strict do
    @object.strict?
  end
  attribute :floating do
    @object.floating?
  end
  attribute :concurrent do
    @object.concurrent?
  end
  attribute :protected do
    @object.protected?
  end
  attribute :max_machines do
    @object.max_machines
  end
  attribute :max_cores do
    @object.max_cores
  end
  attribute :max_uses do
    @object.max_uses
  end
  attribute :require_check_in do
    @object.requires_check_in?
  end
  attribute :last_validated do
    @object.last_validated_at
  end
  attribute :last_check_in do
    @object.last_check_in_at
  end
  attribute :next_check_in do
    @object.next_check_in_at
  end
  attribute :metadata do
    @object.metadata&.transform_keys { |k| k.to_s.camelize :lower } or {}
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
  relationship :product do
    linkage always: true do
      { type: :products, id: @object.policy&.product_id }
    end
    link :related do
      @url_helpers.v1_account_license_product_path @object.account_id, @object
    end
  end
  relationship :policy do
    linkage always: true do
      { type: :policies, id: @object.policy_id }
    end
    link :related do
      @url_helpers.v1_account_license_policy_path @object.account_id, @object
    end
  end
  relationship :user do
    linkage always: true do
      if @object.user_id.present?
        { type: :users, id: @object.user_id }
      else
        nil
      end
    end
    link :related do
      @url_helpers.v1_account_license_user_path @object.account_id, @object
    end
  end
  relationship :machines do
    link :related do
      @url_helpers.v1_account_license_machines_path @object.account_id, @object
    end
    meta do
      {
        cores: @object.machines_core_count || 0,
        count: @object.machines_count || 0,
      }
    end
  end
  relationship :tokens do
    link :related do
      @url_helpers.v1_account_license_tokens_path @object.account_id, @object
    end
  end

  relationship :entitlements do
    link :related do
      @url_helpers.v1_account_license_entitlements_path @object.account_id, @object
    end
  end

  link :self do
    @url_helpers.v1_account_license_path @object.account_id, @object
  end
end
