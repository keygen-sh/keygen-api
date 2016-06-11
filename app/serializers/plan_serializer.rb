class PlanSerializer < BaseSerializer
  attributes :id, :name, :price, :max_products, :max_users, :max_policies,
             :max_licenses

  def id
    object.hashid
  end
end
