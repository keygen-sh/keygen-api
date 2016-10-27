class Role < ApplicationRecord
  ALLOWED_ROLES = %w[user admin product].freeze

  belongs_to :resource, polymorphic: true

  validates :resource, presence: { message: "must exist" }
  validates :name, inclusion: { in: ALLOWED_ROLES, message: "must be a valid role" }
end
