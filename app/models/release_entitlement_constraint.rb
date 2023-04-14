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

  scope :accessible_by, -> accessor {
    case accessor
    in role: { name: 'admin' }
      self.all
    in role: { name: 'environment' }
      self.for_environment(accessor.id)
    in role: { name: 'product' }
      self.for_product(accessor.id)
    in role: { name: 'license' }
      self.for_license(accessor.id)
    in role: { name: 'user' }
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
