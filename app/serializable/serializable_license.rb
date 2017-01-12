class SerializableLicense < SerializableBase
  type :licenses

  attribute :key, unless: -> { @object.policy.encrypted? && @object.raw.nil? } do
    if @object.policy.encrypted?
      @object.raw
    else
      @object.key
    end
  end
  attribute :expiry
  attribute :encrypted do
    @object.policy.encrypted?
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
    link :related do
      @url_helpers.v1_account_path @object.account
    end
  end
  relationship :product do
    link :related do
      @url_helpers.v1_account_license_product_path @object.account, @object
    end
  end
  relationship :policy do
    link :related do
      @url_helpers.v1_account_license_policy_path @object.account, @object
    end
  end
  relationship :user, unless: -> { @object.user.nil? } do
    link :related do
      # TODO: https://github.com/jsonapi-rb/jsonapi-serializable/issues/49
      @url_helpers.v1_account_license_user_path @object.account, @object if @object.user
    end
  end
  relationship :machines do
    link :related do
      @url_helpers.v1_account_license_machines_path @object.account, @object
    end
  end

  link :self do
    @url_helpers.v1_account_license_path @object.account, @object
  end
end
