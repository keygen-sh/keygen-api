# frozen_string_literal: true

class PolicyEntitlement < ApplicationRecord
  include Limitable
  include Pageable

  belongs_to :account
  belongs_to :policy
  belongs_to :entitlement

  validates :account, presence: { message: 'must exist' }
  validates :policy,
    presence: { message: 'must exist' },
    scope: { by: :account_id }
  validates :entitlement,
    uniqueness: { message: 'already exists', scope: [:account_id, :policy_id, :entitlement_id] },
    presence: { message: 'must exist' },
    scope: { by: :account_id }
end
