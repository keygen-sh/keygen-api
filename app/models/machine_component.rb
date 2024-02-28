# frozen_string_literal: true

class MachineComponent < ApplicationRecord
  include Environmental
  include Accountable
  include Limitable
  include Orderable
  include Pageable

  belongs_to :machine,
    inverse_of: :components
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
  has_account default: -> { machine&.account_id }

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
    next if
      machine.nil?

    # Special case where fingerprints could be duplicated in the actual nested
    # association params, so this adds better error messaging vs a plain
    # 409 Conflict error via the unique index violation.
    if !machine.persisted? && machine.components_attributes_assigned?
      count = machine.components.count { _1.fingerprint == component.fingerprint }

      component.errors.add(:fingerprint, :conflict, message: 'is duplicated') if
        count > 1
    end

    # FIXME(ezekg) We're accessing machine.#{assoc} here because the machine may
    #              not be persisted yet and has_one :through associations are
    #              not available on unpersisted records.
    #
    #              See: https://github.com/rails/rails/issues/33155
    case
    when unique_per_account?
      errors.add :fingerprint, :taken, message: "has already been taken for this account" if account.machine_components.exists?(fingerprint:)
    when unique_per_product?
      errors.add :fingerprint, :taken, message: "has already been taken for this product" if account.machine_components.joins(:product).exists?(fingerprint:, products: { id: machine.product })
    when unique_per_policy?
      errors.add :fingerprint, :taken, message: "has already been taken for this policy" if account.machine_components.joins(:policy).exists?(fingerprint:, policies: { id: machine.policy })
    when unique_per_license?
      errors.add :fingerprint, :taken, message: "has already been taken for this license" if account.machine_components.joins(:license).exists?(fingerprint:, licenses: { id: machine.license })
    when unique_per_machine?
      errors.add :fingerprint, :taken, message: "has already been taken" if machine.components.exists?(fingerprint:)
    end
  end

  scope :for_product, -> id { joins(:product).where(product: { id: }) }
  scope :for_license, -> id { joins(:license).where(license: { id: }) }
  scope :for_machine, -> id { joins(:machine).where(machine: { id: }) }
  scope :for_user,    -> id { joins(:user).where(user: { id: }) }

  scope :with_fingerprint, -> fingerprint { where(fingerprint:) }

  # FIXME(ezekg) https://github.com/rails/rails/issues/33155
  def unique_per_account?
    return false if machine.policy.nil?

    machine.policy.component_unique_per_account?
  end

  def unique_per_product?
    return false if machine.policy.nil?

    machine.policy.component_unique_per_product?
  end

  def unique_per_policy?
    return false if machine.policy.nil?

    machine.policy.component_unique_per_policy?
  end

  def unique_per_license?
    return false if machine.policy.nil?

    machine.policy.component_unique_per_license?
  end

  def unique_per_machine?
    return false if machine.policy.nil?

    machine.policy.component_unique_per_license?
  end
end
