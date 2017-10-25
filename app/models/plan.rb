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
#
# Indexes
#
#  index_plans_on_created_at_and_id       (created_at,id) UNIQUE
#  index_plans_on_created_at_and_plan_id  (created_at,plan_id)
#
