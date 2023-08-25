# frozen_string_literal: true

class ReleaseEntitlementConstraint < ApplicationRecord
  include Environmental
  include Limitable
  include Orderable
  include Pageable

  belongs_to :account
  belongs_to :release,
    inverse_of: :constraints
  belongs_to :entitlement,
    inverse_of: :release_entitlement_constraints
  has_one :product,
    through: :release

  has_environment default: -> { release&.environment_id }

  validates :release,
    scope: { by: :account_id }

  validates :entitlement,
    uniqueness: { message: 'already exists', scope: %i[account_id release_id entitlement_id] },
    scope: { by: :account_id }

  validate on: :create do |constraint|
    next if
      release.nil? || release.persisted? # detect if constraint is from nested params

    # Special case where entitlements could be duplicated in the actual nested
    # association params, so this adds better error messaging vs a plain
    # 409 Conflict error via the unique index violation.
    if release.constraints_attributes_assigned?
      count = release.constraints.count { _1.entitlement_id == constraint.entitlement_id }

      constraint.errors.add(:entitlement, :conflict, message: 'is duplicated') if
        count > 1
    end
  end

  scope :accessible_by, -> accessor {
    case accessor
    in role: Role(:admin)
      self.all
    in role: Role(:environment)
      self.for_environment(accessor.id)
    in role: Role(:product)
      self.for_product(accessor.id)
    in role: Role(:license)
      self.for_license(accessor.id)
    in role: Role(:user)
      self.for_user(accessor.id)
    else
      self.none
    end
  }

  scope :for_product, -> id {
    joins(:product).where(product: { id: })
  }

  scope :for_user, -> user {
    joins(product: %i[users])
      .reorder(created_at: DEFAULT_SORT_ORDER)
      .where(
        product: { distribution_strategy: ['LICENSED', nil] },
        users: { id: user },
      )
      .distinct
      .union(
        self.open
      )
  }

  scope :for_license, -> license {
    joins(product: %i[licenses])
      .reorder(created_at: DEFAULT_SORT_ORDER)
      .where(
        product: { distribution_strategy: ['LICENSED', nil] },
        licenses: { id: license },
      )
      .distinct
      .union(
        self.open
      )
  }

  scope :licensed, -> {
    joins(:product)
      .reorder(created_at: DEFAULT_SORT_ORDER)
      .where(product: { distribution_strategy: ['LICENSED', nil] })
      .distinct
  }

  scope :open, -> {
    joins(:product)
      .reorder(created_at: DEFAULT_SORT_ORDER)
      .where(product: { distribution_strategy: 'OPEN' })
      .distinct
  }

  scope :closed, -> {
    joins(:product)
      .reorder(created_at: DEFAULT_SORT_ORDER)
      .where(product: { distribution_strategy: 'CLOSED' })
      .distinct
  }
end
