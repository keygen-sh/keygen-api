# frozen_string_literal: true

class ReleaseArch < ApplicationRecord
  include Limitable
  include Orderable
  include Pageable

  belongs_to :account,
    inverse_of: :release_arches
  has_many :artifacts,
    class_name: 'ReleaseArtifact',
    inverse_of: :arch
  has_many :releases,
    through: :artifacts
  has_many :products,
    through: :releases
  has_many :licenses,
    through: :products
  has_many :users,
    through: :licenses

  validates :key,
    presence: true,
    uniqueness: { message: 'already exists', scope: :account_id }

  scope :for_product, -> id {
    joins(:products).where(products: { id: id }).distinct
  }

  scope :for_user, -> user {
    joins(products: %i[users])
      .where(
        products: { distribution_strategy: ['LICENSED', nil] },
        users: { id: user },
      )
      .distinct
      .union(
        self.open
      )
  }

  scope :for_license, -> license {
    joins(products: %i[licenses])
      .where(
        products: { distribution_strategy: ['LICENSED', nil] },
        licenses: { id: license },
      )
      .distinct
      .union(
        self.open
      )
  }

  scope :licensed, -> { joins(:products).where(products: { distribution_strategy: ['LICENSED', nil] }).distinct }
  scope :open, -> { joins(:products).where(products: { distribution_strategy: 'OPEN' }).distinct }
  scope :closed, -> { joins(:products).where(products: { distribution_strategy: 'CLOSED' }).distinct }

  scope :with_releases, -> { joins(products: %i[releases]).distinct }
end
