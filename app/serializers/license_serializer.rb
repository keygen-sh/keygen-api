# frozen_string_literal: true

class LicenseSerializer < BaseSerializer
  type 'licenses'

  attribute :name
  attribute :key, unless: -> { @object.legacy_encrypted? && @object.raw.nil? } do
    if @object.legacy_encrypted?
      @object.raw
    else
      @object.key
    end
  end
  attribute :expiry
  attribute :status
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
  attribute :protected do
    @object.protected?
  end
  attribute :version do
    @object.last_validated_version
  end
  attribute :max_machines
  attribute :max_processes
  attribute :max_cores
  attribute :max_uses
  attribute :require_heartbeat do
    @object.require_heartbeat?
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
  attribute :last_check_out do
    @object.last_check_out_at
  end
  ee do
    attribute :permissions, if: -> { @account.ent? } do
      @object.permissions.actions
    end
  end
  attribute :metadata do
    @object.metadata&.deep_transform_keys { _1.to_s.camelize :lower } or {}
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

  relationship :group do
    linkage always: true do
      if @object.group_id?
        { type: :groups, id: @object.group_id }
      else
        nil
      end
    end
    link :related do
      @url_helpers.v1_account_license_group_path @object.account_id, @object
    end
  end

  relationship :owner do
    linkage always: true do
      if @object.owner_id?
        { type: :users, id: @object.owner_id }
      else
        nil
      end
    end
    link :related do
      @url_helpers.v1_account_license_owner_path @object.account_id, @object
    end
  end

  relationship :users do
    link :related do
      @url_helpers.v1_account_license_users_path @object.account_id, @object
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
