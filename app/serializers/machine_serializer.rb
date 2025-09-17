# frozen_string_literal: true

class MachineSerializer < BaseSerializer
  type 'machines'

  attribute :fingerprint
  attribute :cores
  attribute :memory
  attribute :disk
  attribute :ip
  attribute :hostname
  attribute :platform
  attribute :name
  attribute :require_heartbeat do
    @object.requires_heartbeat?
  end
  attribute :heartbeat_status
  attribute :heartbeat_duration
  attribute :max_processes
  attribute :last_check_out do
    @object.last_check_out_at
  end
  attribute :last_heartbeat do
    @object.last_heartbeat_at
  end
  attribute :next_heartbeat do
    @object.next_heartbeat_at
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
      { type: :products, id: @object.product&.id }
    end
    link :related do
      @url_helpers.v1_account_machine_product_path @object.account_id, @object
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
      @url_helpers.v1_account_machine_group_path @object.account_id, @object
    end
  end

  relationship :license do
    linkage always: true do
      { type: :licenses, id: @object.license_id }
    end
    link :related do
      @url_helpers.v1_account_machine_license_path @object.account_id, @object
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
      @url_helpers.v1_account_machine_owner_path @object.account_id, @object
    end
  end

  relationship :components do
    link :related do
      @url_helpers.v1_account_machine_machine_components_path @object.account_id, @object
    end
  end

  relationship :processes do
    link :related do
      @url_helpers.v1_account_machine_machine_processes_path @object.account_id, @object
    end
  end

  link :self do
    @url_helpers.v1_account_machine_path @object.account_id, @object
  end
end
