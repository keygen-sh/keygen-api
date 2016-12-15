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

  relationship :tokens
  relationship :account do
    link :related do
      @url_helpers.v1_account_path @object.account
    end
  end
  relationship :products do
    link :related do
      @url_helpers.v1_account_products_path @object.account, user: @object.hashid
    end
  end
  relationship :licenses do
    link :related do
      @url_helpers.v1_account_licenses_path @object.account, user: @object.hashid
    end
  end
  relationship :machines do
    link :related do
      @url_helpers.v1_account_machines_path @object.account, user: @object.hashid
    end
  end
end
