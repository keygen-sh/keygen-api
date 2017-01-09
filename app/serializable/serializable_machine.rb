class SerializableMachine < SerializableBase
  type :machines

  attribute :fingerprint
  attribute :ip
  attribute :hostname
  attribute :platform
  attribute :name
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
    link :related do
      @url_helpers.v1_account_path @object.account
    end
  end
  relationship :product do
    link :related do
      @url_helpers.v1_account_machine_product_path @object.account, @object
    end
  end
  relationship :license do
    link :related do
      @url_helpers.v1_account_machine_license_path @object.account, @object
    end
  end
  relationship :user do
    link :related do
      @url_helpers.v1_account_machine_user_path @object.account, @object
    end
  end

  link :self do
    @url_helpers.v1_account_machine_path @object.account, @object
  end
end
