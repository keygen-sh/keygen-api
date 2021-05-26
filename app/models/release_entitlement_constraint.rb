# frozen_string_literal: true

class ReleaseEntitlementConstraint < ApplicationRecord
  include Limitable
  include Pageable

  belongs_to :account
  belongs_to :release,
    inverse_of: :constraints
  belongs_to :entitlement,
    inverse_of: :release_entitlement_constraints

  validates :account,
    presence: { message: 'must exist' }
  validates :release,
    presence: { message: 'must exist' }
  validates :entitlement,
    presence: { message: 'must exist' },
    uniqueness: { message: 'already exists', scope: %i[account_id release_id entitlement_id] }
end
