# frozen_string_literal: true

class ReleaseArch < ApplicationRecord
  include Accountable
  include Limitable
  include Orderable
  include Pageable

  has_many :artifacts,
    class_name: 'ReleaseArtifact',
    inverse_of: :arch
  has_many :releases,
    through: :artifacts
  has_many :products,
    through: :releases

  has_account inverse_of: :release_arches

  validates :key,
    presence: true,
    uniqueness: { message: 'already exists', scope: :account_id }

  before_create -> { self.key = key&.downcase&.strip }

  scope :for_environment, -> environment, strict: false {
    joins(:artifacts)
      .reorder(created_at: DEFAULT_SORT_ORDER)
      .where(
        artifacts: ReleaseArtifact.where('release_artifacts.account_id = release_arches.account_id')
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
