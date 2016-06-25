class PlanSerializer < BaseSerializer
  attributes :id, :name, :price, :max_products, :max_users, :max_policies,
             :max_licenses, :created, :updated

  def id
    object.hashid
  end

  def created
    object.created_at
  end

  def updated
    object.updated_at
  end
end
