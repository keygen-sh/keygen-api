class Plan < ApplicationRecord
  include Limitable
  include Pageable

  has_many :accounts

  scope :visible, -> { where private: false }
  scope :hidden, -> { where private: true }

  def private?
    private
  end

  def public?
    !private
  end
end

# == Schema Information
#
# Table name: plans
#
#  id             :uuid             not null, primary key
#  name           :string
#  price          :integer
#  max_users      :integer
#  max_policies   :integer
#  max_licenses   :integer
#  created_at     :datetime         not null
#  updated_at     :datetime         not null
#  max_products   :integer
#  plan_id        :string
#  private        :boolean          default(FALSE)
#  trial_duration :integer
#  max_reqs       :integer
#  max_admins     :integer
#
# Indexes
#
#  index_plans_on_id_and_created_at       (id,created_at) UNIQUE
#  index_plans_on_plan_id_and_created_at  (plan_id,created_at)
#
