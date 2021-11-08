# frozen_string_literal: true

class ReleaseArtifact < ApplicationRecord
  include Limitable
  include Pageable

  belongs_to :account
  belongs_to :product
  belongs_to :release
  has_many :users,
    through: :product
  has_many :licenses,
    through: :product

  validates :account,
    presence: { message: 'must exist' }
  validates :product,
    presence: { message: 'must exist' },
    scope: { by: :account_id }
  validates :release,
    presence: { message: 'must exist' },
    scope: { by: :account_id }

  scope :for_product, -> product {
    where(product: product)
  }

  scope :for_user, -> user {
    joins(product: %i[users])
      .where(
        product: { distribution_strategy: ['LICENSED', nil] },
        users: { id: user },
      )
      .union(
        self.open
      )
  }

  scope :for_license, -> license {
    joins(product: %i[licenses])
      .where(
        product: { distribution_strategy: ['LICENSED', nil] },
        licenses: { id: license },
      )
      .union(
        self.open
      )
  }

  scope :licensed, -> { joins(:product).where(product: { distribution_strategy: ['LICENSED', nil] }) }
  scope :open, -> { joins(:product).where(product: { distribution_strategy: 'OPEN' }) }
  scope :closed, -> { joins(:product).where(product: { distribution_strategy: 'CLOSED' }) }
end
