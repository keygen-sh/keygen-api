# frozen_string_literal: true

class ReleasePlatform < ApplicationRecord
  include Limitable
  include Orderable
  include Pageable

  belongs_to :account,
    inverse_of: :release_platforms
  has_many :artifacts,
    class_name: 'ReleaseArtifact',
    inverse_of: :platform
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

  before_create -> { self.key = key&.downcase&.strip }

  scope :for_environment, -> environment, strict: false {
    joins(:artifacts)
      .reorder(created_at: DEFAULT_SORT_ORDER)
      .where(
        artifacts: ReleaseArtifact.where('release_artifacts.account_id = release_platforms.account_id')
                                  .for_environment(environment, strict:),
      )
      .distinct
  }

  scope :for_product, -> id {
    joins(:products)
      .reorder(created_at: DEFAULT_SORT_ORDER)
      .where(products: { id: id })
      .distinct
  }

  scope :for_user, -> user {
    joins(products: %i[users])
      .reorder(created_at: DEFAULT_SORT_ORDER)
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
      .reorder(created_at: DEFAULT_SORT_ORDER)
      .where(
        products: { distribution_strategy: ['LICENSED', nil] },
        licenses: { id: license },
      )
      .distinct
      .union(
        self.open
      )
  }

  scope :licensed, -> {
    joins(:products)
      .reorder(created_at: DEFAULT_SORT_ORDER)
      .where(products: { distribution_strategy: ['LICENSED', nil] })
      .distinct
  }

  scope :open, -> {
    joins(:products)
      .reorder(created_at: DEFAULT_SORT_ORDER)
      .where(products: { distribution_strategy: 'OPEN' })
      .distinct
  }

  scope :closed, -> {
    joins(:products)
      .reorder(created_at: DEFAULT_SORT_ORDER)
      .where(products: { distribution_strategy: 'CLOSED' })
      .distinct
  }

  scope :with_releases, -> { where_assoc_exists(:releases) }
end
