class SerializableProduct < SerializableBase
  type :products

  attribute :name
  attribute :platforms
  attribute :metadata do
    @object.metadata&.transform_keys { |k| k.camelize :lower } or {}
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
  relationship :policies do
    link :related do
      @url_helpers.v1_account_product_policies_path @object.account, @object
    end
  end
  relationship :licenses do
    link :related do
      @url_helpers.v1_account_product_licenses_path @object.account, @object
    end
  end
  relationship :machines do
    link :related do
      @url_helpers.v1_account_product_machines_path @object.account, @object
    end
  end
  relationship :users do
    link :related do
      @url_helpers.v1_account_product_users_path @object.account, @object
    end
  end
  relationship :tokens do
    linkage always: true do
      @object.tokens.map { |t| { type: "tokens", id: t.id } }
    end
  end

  link :self do
    @url_helpers.v1_account_product_path @object.account, @object
  end
end
