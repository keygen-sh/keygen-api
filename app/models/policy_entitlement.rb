# frozen_string_literal: true

class PolicyEntitlement < ApplicationRecord
  include Keygen::PortableClass
  include Environmental
  include Accountable
  include Limitable
  include Orderable
  include Pageable

  belongs_to :policy
  belongs_to :entitlement

  has_environment default: -> { policy&.environment_id }
  has_account default: -> { policy&.account_id }

  validates :policy,
    scope: { by: :account_id }

  validates :entitlement,
    uniqueness: { message: 'already exists', scope: [:account_id, :policy_id, :entitlement_id] },
    scope: { by: :account_id }

  delegate :code,
    to: :entitlement,
    allow_nil: true
end
