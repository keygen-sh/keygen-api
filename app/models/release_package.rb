# frozen_string_literal: true

class ReleasePackage < ApplicationRecord
  include Environmental
  include Limitable
  include Orderable
  include Pageable
  include Diffable

  belongs_to :account,
    inverse_of: :release_packages
  belongs_to :product,
    inverse_of: :release_packages
  belongs_to :engine,
    foreign_key: :release_engine_id,
    class_name: 'ReleaseEngine',
    optional: true
  has_many :releases,
    inverse_of: :package,
    dependent: :destroy_async
  has_many :artifacts,
    through: :releases,
    source: :artifacts
  has_many :licenses,
    through: :product
  has_many :users,
    through: :product

  has_environment default: -> { product&.environment_id }

  validates :product,
    scope: { by: :account_id }

  validates :engine,
    presence: { message: 'must exist' },
    if: :engine_id?

  validates :key,
    exclusion: { in: EXCLUDED_ALIASES, message: 'is reserved' },
    uniqueness: { message: 'already exists', scope: :account_id },
    length: { minimum: 1, maximum: 255 },
    format: { without: UUID_RE },
    allow_blank: false,
    presence: true

  validates :name,
    length: { minimum: 1, maximum: 255 },
    allow_blank: false,
    presence: true

  scope :for_product, -> id {
    joins(:product).where(product: { id: })
  }

  scope :for_user, -> id {
    joins(:product, :users)
      .where(
        product: { distribution_strategy: ['LICENSED', nil] },
        users: { id: },
      )
      .union(
        self.open,
      )
  }

  scope :for_license, -> id {
    joins(:product, :licenses)
      .where(
        product: { distribution_strategy: ['LICENSED', nil] },
        licenses: { id: },
      )
      .union(
        self.open,
      )
  }

  scope :licensed, -> { joins(:product).where(product: { distribution_strategy: ['LICENSED', nil] }) }
  scope :open,     -> { joins(:product).where(product: { distribution_strategy: 'OPEN' }) }
  scope :closed,   -> { joins(:product).where(product: { distribution_strategy: 'CLOSED' }) }

  scope :for_engine, -> key {
    joins(:engine).where(release_engines: { key: })
  }

  scope :pypi, -> {
    where(engine: ReleaseEngine.pypi)
  }

  def engine_id? = release_engine_id?
  def engine_id  = release_engine_id
  def engine_id=(id)
    self.release_engine_id = id
  end
end