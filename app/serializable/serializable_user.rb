class SerializableUser < SerializableBase
  type :users

  attribute :name
  attribute :email
  attribute :metadata
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
      @url_helpers.v1_account_products_path @object.account, user: @object.id
    end
  end
  relationship :licenses do
    link :related do
      @url_helpers.v1_account_licenses_path @object.account, user: @object.id
    end
  end
  relationship :machines do
    link :related do
      @url_helpers.v1_account_machines_path @object.account, user: @object.id
    end
  end
  relationship :tokens

  link :self do
    @url_helpers.v1_account_user_path @object.account, @object
  end
end
