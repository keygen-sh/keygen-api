# frozen_string_literal: true

class LicenseEntitlement < ApplicationRecord
  include Keygen::Exportable
  include Environmental
  include Accountable
  include Limitable
  include Orderable
  include Pageable

  belongs_to :license
  belongs_to :entitlement
  has_one :policy,
    through: :license

  has_environment default: -> { license&.environment_id }
  has_account default: -> { license&.account_id }

  validates :license,
    scope: { by: :account_id }

  validates :entitlement,
    uniqueness: { message: 'already exists', scope: [:account_id, :license_id, :entitlement_id] },
    scope: { by: :account_id }

  validate on: :create do
    next unless
      policy.present? && policy.policy_entitlements.exists?(entitlement_id:)

    errors.add :entitlement, :conflict, message: 'already exists (entitlement is attached through policy)'
  end

  delegate :code,
    to: :entitlement,
    allow_nil: true
end
