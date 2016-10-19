class Role < ApplicationRecord
  ALLOWED_ROLES = %w[admin user product].freeze

  belongs_to :resource, polymorphic: true

  validates :name, inclusion: { in: ALLOWED_ROLES, message: "%{value} is not a valid role" }
end
