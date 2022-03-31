# frozen_string_literal: true

class LicenseEntitlement < ApplicationRecord
  include Limitable
  include Orderable
  include Pageable

  belongs_to :account
  belongs_to :license
  belongs_to :entitlement
  has_one :policy, through: :license

  validates :license,
    scope: { by: :account_id }
  validates :entitlement,
    uniqueness: { message: 'already exists', scope: [:account_id, :license_id, :entitlement_id] },
    scope: { by: :account_id }

  validate on: :create do
    errors.add :entitlement, :conflict, message: 'already exists (entitlement is attached through policy)' if policy.policy_entitlements.exists?(entitlement_id: entitlement_id)
  end

  delegate :code,
    to: :entitlement,
    allow_nil: true
end
