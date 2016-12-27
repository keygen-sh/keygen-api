class SerializableUser < SerializableBase
  type :users

  attribute :name
  attribute :email
  attribute :metadata do
    @object.metadata&.transform_keys { |k| k.camelize :lower } or {}
  end
  attribute :role do
    @object.role&.name
  end
  attribute :created do
    @object.created_at
  end
  attribute :updated do
    @object.updated_at
  end

  relationship :account do
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

  link :self do
    @url_helpers.v1_account_user_path @object.account, @object
  end
end
