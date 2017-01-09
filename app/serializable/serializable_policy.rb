class SerializablePolicy < SerializableBase
  type :policies

  attribute :name
  attribute :price
  attribute :duration
  attribute :strict
  attribute :recurring
  attribute :floating
  attribute :use_pool
  attribute :max_machines
  attribute :encrypted
  attribute :protected
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
      @url_helpers.v1_account_policy_product_path @object.account, @object
    end
  end
  relationship :licenses do
    link :related do
      @url_helpers.v1_account_policy_licenses_path @object.account, @object
    end
  end
  relationship :pool, if: -> { @object.pool? }

  link :self do
    @url_helpers.v1_account_policy_path @object.account, @object
  end
end
