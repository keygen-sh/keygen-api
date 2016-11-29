class Plan < ApplicationRecord
  include Limitable
  include Pageable

  acts_as_paranoid

  has_many :accounts
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
#  deleted_at   :datetime
#
# Indexes
#
#  index_plans_on_deleted_at  (deleted_at)
#  index_plans_on_plan_id     (plan_id)
#
