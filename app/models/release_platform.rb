# frozen_string_literal: true

class ReleasePlatform < ApplicationRecord
  include Keygen::PortableClass
  include Accountable
  include Limitable
  include Orderable
  include Pageable

  has_many :artifacts,
    class_name: 'ReleaseArtifact',
    inverse_of: :platform
  has_many :releases,
    through: :artifacts
  has_many :products,
    through: :releases

  has_account inverse_of: :release_platforms

  validates :key,
    presence: true,
    uniqueness: { message: 'already exists', scope: :account_id },
    length: { maximum: 255 }

  validates :name,
    length: { maximum: 255 }

  validates :metadata,
    length: { maximum: 64, message: 'too many keys (exceeded limit of 64 keys)' }

  before_create -> { self.key = key&.downcase&.strip }

  scope :for_environment, -> environment, strict: environment.nil? {
    joins(:artifacts)
      .reorder("#{table_name}.created_at": DEFAULT_SORT_ORDER)
      .where(
        artifacts: ReleaseArtifact.where('release_artifacts.account_id = release_platforms.account_id')
                                  .for_environment(environment, strict:),
      )
      .distinct
  }

  scope :for_product, -> id {
    joins(:products)
      .reorder("#{table_name}.created_at": DEFAULT_SORT_ORDER)
      .where(products: { id: id })
      .distinct
  }

  scope :for_user, -> user {
    joins(products: %i[licenses])
      .reorder("#{table_name}.created_at": DEFAULT_SORT_ORDER)
      .where(
        products: { distribution_strategy: ['LICENSED', nil] },
        licenses: { id: License.for_user(user) },
      )
      .distinct
      .union(open)
      .reorder(
        "#{table_name}.created_at": DEFAULT_SORT_ORDER,
      )
  }

  scope :for_license, -> license {
    joins(products: %i[licenses])
      .reorder("#{table_name}.created_at": DEFAULT_SORT_ORDER)
      .where(
        products: { distribution_strategy: ['LICENSED', nil] },
        licenses: { id: license },
      )
      .distinct
      .union(open)
      .reorder(
        "#{table_name}.created_at": DEFAULT_SORT_ORDER,
      )
  }

  scope :licensed, -> {
    joins(:products)
      .reorder("#{table_name}.created_at": DEFAULT_SORT_ORDER)
      .where(products: { distribution_strategy: ['LICENSED', nil] })
      .distinct
  }

  scope :open, -> {
    joins(:products)
      .reorder("#{table_name}.created_at": DEFAULT_SORT_ORDER)
      .where(products: { distribution_strategy: 'OPEN' })
      .distinct
  }

  scope :closed, -> {
    joins(:products)
      .reorder("#{table_name}.created_at": DEFAULT_SORT_ORDER)
      .where(products: { distribution_strategy: 'CLOSED' })
      .distinct
  }

  scope :with_releases, -> { where_assoc_exists(:releases) }
end
