# frozen_string_literal: true

class ReleasePlatform < ApplicationRecord
  WIN_KEYS = %w[windows win win32 dos msdos]
  MAC_KEYS = %w[darwin osx mac macos]

  include Limitable
  include Pageable

  belongs_to :account,
    inverse_of: :release_platforms
  has_many :releases,
    inverse_of: :platform
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
    uniqueness: { message: 'already exists', scope: :account_id }

  scope :for_product, -> id {
    joins(:products).where(products: { id: id }).distinct
  }

  scope :for_user, -> id {
    joins(:users).where(users: { id: id }).distinct
  }

  scope :for_license, -> id {
    joins(:licenses).where(licenses: { id: id }).distinct
  }

  scope :with_releases, -> { joins(:releases).distinct }

  def mac?
    MAC_KEYS.include?(key)
  end

  def win?
    WIN_KEYS.include?(key)
  end

  def nix?
    !win?
  end
end
