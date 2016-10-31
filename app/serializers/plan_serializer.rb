class PlanSerializer < BaseSerializer
  type :plans

  attributes [
    :id,
    :name,
    :price,
    :max_products,
    :max_users,
    :max_policies,
    :max_licenses,
    :created,
    :updated
  ]
end

# == Schema Information
#
# Table name: plans
#
#  id           :integer          not null, primary key
#  name         :string
#  price        :integer
#  max_users    :integer
#  max_policies :integer
#  max_licenses :integer
#  created_at   :datetime         not null
#  updated_at   :datetime         not null
#  max_products :integer
#  plan_id      :string
#
# Indexes
#
#  index_plans_on_plan_id  (plan_id)
#
