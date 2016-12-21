class SerializableMachine < SerializableBase
  type :machines

  attribute :fingerprint
  attribute :ip
  attribute :hostname
  attribute :platform
  attribute :name
  attribute :metadata
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
  relationship :product do
    link :related do
      @url_helpers.v1_account_product_path @object.account, @object.product
    end
  end
  relationship :license do
    link :related do
      @url_helpers.v1_account_license_path @object.account, @object.license
    end
  end
  relationship :user do
    link :related do
      @url_helpers.v1_account_user_path @object.account, @object.user
    end
  end
end
