class SerializablePlan < SerializableBase
  type :plans

  attribute :name
  attribute :price
  attribute :max_users
  attribute :max_policies
  attribute :max_licenses
  attribute :max_products
  attribute :created do
    @object.created_at
  end
  attribute :updated do
    @object.updated_at
  end
end
