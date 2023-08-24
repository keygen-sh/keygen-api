# frozen_string_literal: true

class MachineComponent < ApplicationRecord
  include Environmental
  include Limitable
  include Orderable
  include Pageable

  belongs_to :account
  belongs_to :machine
  has_one :group,
    through: :machine
  has_one :license,
    through: :machine
  has_one :product,
    through: :license
  has_one :policy,
    through: :license
  has_one :user,
    through: :license

  has_environment default: -> { machine&.environment_id }

  validates :machine,
    scope: { by: :account_id }

  validates :fingerprint,
    uniqueness: { message: 'has already been taken', scope: %i[machine_id] },
    exclusion: { in: EXCLUDED_ALIASES, message: 'is reserved' },
    presence: true

  validates :name,
    presence: true

  # Fingerprint uniqueness on create
  validate on: :create do |component|
    case
    when uniq_per_account?
      errors.add :fingerprint, :taken, message: "has already been taken for this account" if account.machine_components.exists?(fingerprint:)
    when uniq_per_product?
      errors.add :fingerprint, :taken, message: "has already been taken for this product" if account.machine_components.joins(:product).exists?(fingerprint:, products: { id: product.id })
    when uniq_per_policy?
      errors.add :fingerprint, :taken, message: "has already been taken for this policy" if account.machine_components.joins(:policy).exists?(fingerprint:, policies: { id: policy.id })
    when uniq_per_license?
      errors.add :fingerprint, :taken, message: "has already been taken for this license" if license.components.exists?(fingerprint:)
    when uniq_per_machine?
      errors.add :fingerprint, :taken, message: "has already been taken" if machine.components.exists?(fingerprint:)
    end
  end

  scope :for_product, -> id { joins(:product).where(product: { id: }) }
  scope :for_license, -> id { joins(:license).where(license: { id: }) }
  scope :for_machine, -> id { joins(:machine).where(machine: { id: }) }
  scope :for_user,    -> id { joins(:user).where(user: { id: }) }

  scope :with_fingerprint, -> fingerprint { where(fingerprint:) }

  delegate :uniq_per_account?, :uniq_per_product?, :uniq_per_policy?, :uniq_per_license?, :uniq_per_machine?,
    allow_nil: true,
    to: :machine
end
