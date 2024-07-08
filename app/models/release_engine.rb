# frozen_string_literal: true

class ReleaseEngine < ApplicationRecord
  include Keygen::Exportable
  include Accountable
  include Limitable
  include Orderable
  include Pageable

  ENGINES = %w[
    pypi
    tauri
  ]

  has_many :packages,
    class_name: 'ReleasePackage',
    inverse_of: :engine
  has_many :releases,
    through: :packages
  has_many :products,
    through: :packages

  has_account inverse_of: :release_engines

  validates :key,
    presence: true,
    uniqueness: { message: 'already exists', scope: :account_id },
    inclusion: { in: ENGINES }

  scope :for_environment, -> environment, strict: false {
    joins(:packages)
      .reorder(created_at: DEFAULT_SORT_ORDER)
      .where(
        packages: ReleasePackage.where('release_packages.account_id = release_engines.account_id')
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
    joins(products: %i[licenses])
      .reorder(created_at: DEFAULT_SORT_ORDER)
      .where(
        products: { distribution_strategy: ['LICENSED', nil] },
        licenses: { id: License.for_user(user) },
      )
      .distinct
      .union(open)
      .reorder(
        created_at: DEFAULT_SORT_ORDER,
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
      .union(open)
      .reorder(
        created_at: DEFAULT_SORT_ORDER,
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

  scope :with_packages, -> {
    where_assoc_exists(:packages)
  }

  scope :with_releases, -> {
    where_assoc_exists(:releases)
  }
end
