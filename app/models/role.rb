class Role < ApplicationRecord
  belongs_to :resource, polymorphic: true

  validates :name, inclusion: { in: %w[user admin], message: "must be a valid user role" }, if: -> { resource.is_a? User }
  validates :name, inclusion: { in: %w[product], message: "must be a valid product role" }, if: -> { resource.is_a? Product }
end

# == Schema Information
#
# Table name: roles
#
#  id            :uuid             not null, primary key
#  name          :string
#  resource_type :string
#  created_at    :datetime
#  updated_at    :datetime
#  resource_id   :uuid
#
# Indexes
#
#  index_roles_on_created_at_and_id                             (created_at,id) UNIQUE
#  index_roles_on_created_at_and_name                           (created_at,name)
#  index_roles_on_created_at_and_resource_id_and_resource_type  (created_at,resource_id,resource_type)
#
