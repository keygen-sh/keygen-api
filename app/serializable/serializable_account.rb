class SerializableAccount < SerializableBase
  type :accounts

  attribute :name
  attribute :slug
  attribute :created do
    @object.created_at
  end
  attribute :updated do
    @object.updated_at
  end

  relationship :webhook_endpoints do
    link :related do
      @url_helpers.v1_account_webhook_endpoints_path @object
    end
  end
  relationship :webhook_events do
    link :related do
      @url_helpers.v1_account_webhook_events_path @object
    end
  end
  relationship :products do
    link :related do
      @url_helpers.v1_account_products_path @object
    end
  end
  relationship :policies do
    link :related do
      @url_helpers.v1_account_policies_path @object
    end
  end
  relationship :users do
    link :related do
      @url_helpers.v1_account_users_path @object
    end
  end
  relationship :keys do
    link :related do
      @url_helpers.v1_account_keys_path @object
    end
  end
  relationship :licenses do
    link :related do
      @url_helpers.v1_account_licenses_path @object
    end
  end
  relationship :machines do
    link :related do
      @url_helpers.v1_account_machines_path @object
    end
  end

  link :self do
    @url_helpers.v1_account_path @object
  end
end
