# frozen_string_literal: true

class ReleaseEntitlementConstraint < ApplicationRecord
  include Limitable
  include Pageable

  belongs_to :account
  belongs_to :release
  belongs_to :entitlement

  validates :account,
    presence: { message: 'must exist' }
  validates :release,
    presence: { message: 'must exist' }
  validates :entitlement,
    presence: { message: 'must exist' },
    uniqueness: { message: 'already exists', scope: %i[account_id release_id entitlement_id] }
end
