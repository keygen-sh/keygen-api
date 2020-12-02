# frozen_string_literal: true

class SerializableUser < SerializableBase
  type :users

  attribute :full_name
  attribute :first_name
  attribute :last_name
  attribute :email
  attribute :role do
    @object.role&.name&.dasherize
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
