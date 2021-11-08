# frozen_string_literal: true

class ReleaseChannel < ApplicationRecord
  include Limitable
  include Pageable

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

  validates :account,
    presence: { message: 'must exist' }

  validates :key,
    presence: true,
    uniqueness: { message: 'already exists', scope: :account_id },
    inclusion: { in: %w[stable rc beta alpha dev] }

  scope :for_product, -> id {
    joins(:products).where(products: { id: id }).distinct
  }

  scope :for_user, -> id {
    joins(:users).where(users: { id: id }).distinct
      .union(
        joins(:products).where(products: { distribution_strategy: 'OPEN' }).distinct
      )
  }

  scope :for_license, -> id {
    joins(:licenses).where(licenses: { id: id }).distinct
      .union(
        joins(:products).where(products: { distribution_strategy: 'OPEN' }).distinct
      )
  }

  scope :licensed, -> { joins(:products).where(products: { distribution_strategy: ['LICENSED', nil] }).distinct }
  scope :open, -> { joins(:products).where(products: { distribution_strategy: 'OPEN' }).distinct }
  scope :closed, -> { joins(:products).where(products: { distribution_strategy: 'CLOSED' }).distinct }

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
