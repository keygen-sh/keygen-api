class SerializableKey < SerializableBase
  type :keys

  attribute :key
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
  relationship :product do
    linkage always: true
    link :related do
      @url_helpers.v1_account_key_product_path @object.account, @object
    end
  end
  relationship :policy do
    linkage always: true
    link :related do
      @url_helpers.v1_account_key_policy_path @object.account, @object
    end
  end

  link :self do
    @url_helpers.v1_account_key_path @object.account, @object
  end
end
