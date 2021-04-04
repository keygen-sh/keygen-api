# frozen_string_literal: true

class PolicyEntitlement < ApplicationRecord
  include Limitable
  include Pageable

  belongs_to :account
  belongs_to :policy
  belongs_to :entitlement
  has_one :product, through: :policy

  validates :account, presence: { message: 'must exist' }
  validates :policy, presence: { message: 'must exist' }
  validates :entitlement, presence: { message: 'must exist' }, uniqueness: { message: 'already exists', scope: [:account_id, :policy_id, :entitlement_id] }

  delegate :name, to: :entitlement
  delegate :code, to: :entitlement
  delegate :metadata, to: :entitlement
end
