# frozen_string_literal: true

class Role < ApplicationRecord
  USER_ROLES = %w[user admin developer sales_agent support_agent]
  PRODUCT_ROLES = %w[product]
  LICENSE_ROLES = %w[license]

  belongs_to :resource, polymorphic: true

  validates :name, inclusion: { in: USER_ROLES, message: "must be a valid user role" }, if: -> { resource.is_a? User }
  validates :name, inclusion: { in: PRODUCT_ROLES, message: "must be a valid product role" }, if: -> { resource.is_a? Product }
  validates :name, inclusion: { in: LICENSE_ROLES, message: "must be a valid license role" }, if: -> { resource.is_a? License }
end
