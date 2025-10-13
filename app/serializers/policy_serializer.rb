# frozen_string_literal: true

class PolicySerializer < BaseSerializer
  type 'policies'

  attribute :name
  attribute :duration
  attribute :strict
  attribute :floating
  attribute :use_pool
  attribute :max_machines
  attribute :max_processes
  attribute :max_users
  attribute :max_cores
  attribute :max_memory
  attribute :max_disk
  attribute :max_uses
  attribute :machine_uniqueness_strategy
  attribute :machine_matching_strategy
  attribute :component_uniqueness_strategy
  attribute :component_matching_strategy
  attribute :expiration_strategy
  attribute :expiration_basis
  attribute :renewal_basis
  attribute :transfer_strategy
  attribute :authentication_strategy
  attribute :machine_leasing_strategy
  attribute :process_leasing_strategy
  attribute :overage_strategy
  attribute :scheme
  attribute :encrypted
  attribute :protected
  attribute :require_product_scope
  attribute :require_policy_scope
  attribute :require_machine_scope
  attribute :require_fingerprint_scope
  attribute :require_components_scope
  attribute :require_user_scope
  attribute :require_checksum_scope
  attribute :require_version_scope
  attribute :require_check_in
  attribute :check_in_interval
  attribute :check_in_interval_count
  attribute :heartbeat_duration
  attribute :heartbeat_cull_strategy
  attribute :heartbeat_resurrection_strategy
  attribute :heartbeat_basis
  attribute :require_heartbeat
  attribute :metadata do
    @object.metadata&.deep_transform_keys { it.to_s.camelize :lower } or {}
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
      { type: :products, id: @object.product_id }
    end
    link :related do
      @url_helpers.v1_account_policy_product_path @object.account_id, @object
    end
  end

  relationship :pool do
    link :related do
      @url_helpers.v1_account_policy_keys_path @object.account_id, @object
    end
  end

  relationship :licenses do
    link :related do
      @url_helpers.v1_account_policy_licenses_path @object.account_id, @object
    end
  end

  relationship :entitlements do
    link :related do
      @url_helpers.v1_account_policy_entitlements_path @object.account_id, @object
    end
  end

  link :self do
    @url_helpers.v1_account_policy_path @object.account_id, @object
  end
end
