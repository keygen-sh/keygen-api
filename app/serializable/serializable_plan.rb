class SerializablePlan < SerializableBase
  type :plans

  attribute :name
  attribute :price
  attribute :max_users
  attribute :max_policies
  attribute :max_licenses
  attribute :max_products
  attribute :private, if: -> { @object.private? } do
    @object.private
  end
  attribute :created do
    @object.created_at
  end
  attribute :updated do
    @object.updated_at
  end

  link :self do
    @url_helpers.v1_plan_path @object
  end
end
