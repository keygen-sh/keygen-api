class SerializableUser < SerializableBase
  type :users

  attribute :name
  attribute :email
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
    linkage always: true
    link :related do
      @url_helpers.v1_account_path @object.account
    end
  end
  relationship :products do
    link :related do
      @url_helpers.v1_account_user_products_path @object.account, @object
    end
  end
  relationship :licenses do
    link :related do
      @url_helpers.v1_account_user_licenses_path @object.account, @object
    end
  end
  relationship :machines do
    link :related do
      @url_helpers.v1_account_user_machines_path @object.account, @object
    end
  end
  relationship :tokens do
    link :related do
      @url_helpers.v1_account_user_tokens_path @object.account, @object
    end
  end
  relationship :role do
    link :related do
      @url_helpers.v1_account_user_role_path @object.account, @object
    end
  end

  link :self do
    @url_helpers.v1_account_user_path @object.account, @object
  end
end
