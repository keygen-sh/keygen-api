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
#  name          :string
#  resource_type :string
#  created_at    :datetime
#  updated_at    :datetime
#  deleted_at    :datetime
#  id            :uuid             not null, primary key
#  resource_id   :uuid
#
# Indexes
#
#  index_roles_on_created_at   (created_at)
#  index_roles_on_deleted_at   (deleted_at)
#  index_roles_on_id           (id)
#  index_roles_on_resource_id  (resource_id)
#
