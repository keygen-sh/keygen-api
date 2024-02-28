# frozen_string_literal: true

class UserSerializer < BaseSerializer
  type 'users'

  attribute :full_name
  attribute :first_name
  attribute :last_name
  attribute :email
  attribute :status
  attribute :role do
    @object.role&.name&.dasherize
  end
  attribute :permissions, if: -> { @account.ent? } do
    @object.permissions.actions
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

  relationship :group do
    linkage always: true do
      if @object.group_id?
        { type: :groups, id: @object.group_id }
      else
        nil
      end
    end
    link :related do
      @url_helpers.v1_account_user_group_path @object.account_id, @object
    end
  end

  relationship :products do
    link :related do
      @url_helpers.v1_account_user_products_path @object.account_id, @object
    end
  end

  relationship :licenses do
    link :related do
      @url_helpers.v1_account_user_licenses_path @object.account_id, @object
    end
  end

  relationship :machines do
    link :related do
      @url_helpers.v1_account_user_machines_path @object.account_id, @object
    end
  end

  relationship :tokens do
    link :related do
      @url_helpers.v1_account_user_tokens_path @object.account_id, @object
    end
  end

  relationship :second_factors do
    link :related do
      @url_helpers.v1_account_user_second_factors_path @object.account_id, @object
    end
  end

  link :self do
    @url_helpers.v1_account_user_path @object.account_id, @object
  end
end
