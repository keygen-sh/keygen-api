class SerializableProduct < SerializableBase
  type :products

  attribute :name
  attribute :url
  attribute :platforms
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
  relationship :policies do
    link :related do
      @url_helpers.v1_account_product_policies_path @object.account_id, @object
    end
  end
  relationship :licenses do
    link :related do
      @url_helpers.v1_account_product_licenses_path @object.account_id, @object
    end
  end
  relationship :machines do
    link :related do
      @url_helpers.v1_account_product_machines_path @object.account_id, @object
    end
  end
  relationship :users do
    link :related do
      @url_helpers.v1_account_product_users_path @object.account_id, @object
    end
  end
  relationship :tokens do
    link :related do
      @url_helpers.v1_account_product_tokens_path @object.account_id, @object
    end
  end

  link :self do
    @url_helpers.v1_account_product_path @object.account_id, @object
  end
end
