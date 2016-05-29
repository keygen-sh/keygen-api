class PlanSerializer < BaseSerializer
  attributes :id, :name, :price, :max_users, :max_policies, :max_licenses
  has_many :accounts
end
