# frozen_string_literal: true

class ReleaseEntitlementConstraint < ApplicationRecord
  include Keygen::PortableClass
  include Environmental
  include Accountable
  include Limitable
  include Orderable
  include Pageable

  belongs_to :release,
    inverse_of: :constraints
  belongs_to :entitlement,
    inverse_of: :release_entitlement_constraints
  has_one :product,
    through: :release

  has_environment default: -> { release&.environment_id }
  has_account default: -> { release&.account_id }

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
      count = release.constraints.count { it.entitlement_id == constraint.entitlement_id }

      constraint.errors.add(:entitlement, :conflict, message: 'is duplicated') if
        count > 1
    end
  end

  scope :accessible_by, -> accessor {
    case accessor
    in role: Role(:admin)
      all
    in role: Role(:environment)
      for_environment(accessor.id)
    in role: Role(:product)
      for_product(accessor.id)
    in role: Role(:license)
      for_license(accessor.id)
    in role: Role(:user)
      for_user(accessor.id)
    else
      none
    end
  }

  scope :for_product, -> id {
    joins(:product).where(product: { id: })
  }

  scope :for_user, -> user {
    joins(product: %i[licenses])
      .reorder("#{table_name}.created_at": DEFAULT_SORT_ORDER)
      .where(
        product: { distribution_strategy: ['LICENSED', nil] },
        licenses: { id: License.for_user(user) },
      )
      .distinct
      .union(open)
      .reorder(
        "#{table_name}.created_at": DEFAULT_SORT_ORDER,
      )
  }

  scope :for_license, -> license {
    joins(product: %i[licenses])
      .reorder("#{table_name}.created_at": DEFAULT_SORT_ORDER)
      .where(
        product: { distribution_strategy: ['LICENSED', nil] },
        licenses: { id: license },
      )
      .distinct
      .union(open)
      .reorder(
        "#{table_name}.created_at": DEFAULT_SORT_ORDER,
      )
  }

  scope :licensed, -> {
    joins(:product)
      .reorder("#{table_name}.created_at": DEFAULT_SORT_ORDER)
      .where(product: { distribution_strategy: ['LICENSED', nil] })
      .distinct
  }

  scope :open, -> {
    joins(:product)
      .reorder("#{table_name}.created_at": DEFAULT_SORT_ORDER)
      .where(product: { distribution_strategy: 'OPEN' })
      .distinct
  }

  scope :closed, -> {
    joins(:product)
      .reorder("#{table_name}.created_at": DEFAULT_SORT_ORDER)
      .where(product: { distribution_strategy: 'CLOSED' })
      .distinct
  }
end
