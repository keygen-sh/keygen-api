# frozen_string_literal: true

class GroupSerializer < BaseSerializer
  type 'groups'

  attribute :name
  attribute :max_users
  attribute :max_licenses
  attribute :max_machines
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

  relationship :environment do
    linkage always: true do
      if @object.environment_id?
        { type: :environments, id: @object.environment_id }
      else
        nil
      end
    end
    link :related do
      @url_helpers.v1_account_group_environment_path @object.account_id, @object
    end
  end

  relationship :owners do
    link :related do
      @url_helpers.v1_account_group_owners_path @object.account_id, @object.id
    end
  end

  relationship :users do
    link :related do
      @url_helpers.v1_account_group_users_path @object.account_id, @object.id
    end
  end

  relationship :licenses do
    link :related do
      @url_helpers.v1_account_group_licenses_path @object.account_id, @object.id
    end
  end

  relationship :machines do
    link :related do
      @url_helpers.v1_account_group_machines_path @object.account_id, @object.id
    end
  end

  link :self do
    @url_helpers.v1_account_group_path @object.account_id, @object.id
  end
end
