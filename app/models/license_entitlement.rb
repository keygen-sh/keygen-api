# frozen_string_literal: true

class LicenseEntitlement < ApplicationRecord
  include Limitable
  include Pageable

  belongs_to :account
  belongs_to :license
  belongs_to :entitlement
  has_one :policy, through: :license

  validates :account, presence: { message: 'must exist' }
  validates :license, presence: { message: 'must exist' }
  validates :entitlement, presence: { message: 'must exist' }, uniqueness: { message: 'already exists', scope: [:account_id, :license_id, :entitlement_id] }

  validate on: :create do
    errors.add :entitlement, :conflict, message: 'already exists (entitlement is attached through policy)' if policy.policy_entitlements.exists?(entitlement_id: entitlement_id)
  end
end
