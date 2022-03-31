# frozen_string_literal: true

class PolicyEntitlement < ApplicationRecord
  include Limitable
  include Orderable
  include Pageable

  belongs_to :account
  belongs_to :policy
  belongs_to :entitlement

  validates :policy,
    scope: { by: :account_id }
  validates :entitlement,
    uniqueness: { message: 'already exists', scope: [:account_id, :policy_id, :entitlement_id] },
    scope: { by: :account_id }

  delegate :code,
    to: :entitlement,
    allow_nil: true
end
