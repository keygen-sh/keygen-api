# frozen_string_literal: true

class ReleaseChannel < ApplicationRecord
  include Limitable
  include Orderable
  include Pageable

  CHANNELS = %w[
    stable
    rc
    beta
    alpha
    dev
  ]

  belongs_to :account,
    inverse_of: :release_channels
  has_many :releases,
    inverse_of: :channel
  has_many :products,
    through: :releases
  has_many :licenses,
    through: :products
  has_many :users,
    through: :licenses

  validates :key,
    presence: true,
    uniqueness: { message: 'already exists', scope: :account_id },
    inclusion: { in: CHANNELS }

  before_create -> { self.key = key&.downcase&.strip }

  scope :for_environment, -> environment, strict: false {
    joins(:releases)
      .reorder(created_at: DEFAULT_SORT_ORDER)
      .where(
        releases: Release.where('releases.account_id = release_channels.account_id')
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

  def stable?
    key == 'stable'
  end

  def pre_release?
    !stable?
  end

  def rc?
    key == 'rc'
  end

  def beta?
    key == 'beta'
  end

  def alpha?
    key == 'alpha'
  end

  def dev?
    key == 'dev'
  end
end
