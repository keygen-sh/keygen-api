class Role < ApplicationRecord
  acts_as_paranoid

  belongs_to :resource, polymorphic: true

  validates :name, inclusion: { in: %w[user admin], message: "must be a valid user role" }, if: -> { resource.is_a? User }
  validates :name, inclusion: { in: %w[product], message: "must be a valid product role" }, if: -> { resource.is_a? Product }
end

# == Schema Information
#
# Table name: roles
#
#  id            :integer          not null, primary key
#  name          :string
#  resource_type :string
#  resource_id   :integer
#  created_at    :datetime
#  updated_at    :datetime
#  deleted_at    :datetime
#
# Indexes
#
#  index_roles_on_deleted_at                              (deleted_at)
#  index_roles_on_name_and_resource_type_and_resource_id  (name,resource_type,resource_id)
#
