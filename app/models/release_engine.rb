# frozen_string_literal: true

class ReleaseEngine < ApplicationRecord
  include Keygen::PortableClass
  include Accountable
  include Limitable
  include Orderable
  include Pageable

  ENGINES = %w[
    pypi
    tauri
    raw
    rubygems
  ]

  has_many :packages,
    class_name: 'ReleasePackage',
    inverse_of: :engine,
    dependent: :destroy_async
  has_many :products,
    through: :packages
  has_many :releases,
    through: :packages
  has_many :specifications,
    through: :releases

  has_account inverse_of: :release_engines

  validates :key,
    presence: true,
    uniqueness: { message: 'already exists', scope: :account_id },
    inclusion: { in: ENGINES }

  scope :for_environment, -> environment, strict: false {
    joins(:packages)
      .reorder("#{table_name}.created_at": DEFAULT_SORT_ORDER)
      .where(
        packages: ReleasePackage.where('release_packages.account_id = release_engines.account_id')
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

  scope :with_packages, -> {
    where_assoc_exists(:packages)
  }

  scope :with_releases, -> {
    where_assoc_exists(:releases)
  }

  def pypi?     = key == 'pypi'
  def tauri?    = key == 'tauri'
  def raw?      = key == 'raw'
  def rubygems? = key == 'rubygems'

  ##
  # deconstruct allows pattern pattern matching like:
  #
  #   engine in ReleaseEngine(:rubygems)
  #
  def deconstruct = [key.to_sym]
end
