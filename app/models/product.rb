# frozen_string_literal: true

class Product < ApplicationRecord
  include Limitable
  include Pageable
  include Roleable
  include Searchable

  SEARCH_ATTRIBUTES = %i[id name metadata].freeze
  SEARCH_RELATIONSHIPS = {}.freeze

  DISTRIBUTION_STRATEGIES = %w[
    LICENSED
    OPEN
    CLOSED
  ]

  search attributes: SEARCH_ATTRIBUTES

  belongs_to :account
  has_many :policies, dependent: :destroy
  has_many :keys, through: :policies, source: :pool
  has_many :licenses, through: :policies
  has_many :machines, -> { select('"machines".*, "machines"."id", "machines"."created_at"').distinct('"machines"."id"').reorder(Arel.sql('"machines"."created_at" ASC')) }, through: :licenses
  has_many :users, -> { select('"users".*, "users"."id", "users"."created_at"').distinct('"users"."id"').reorder(Arel.sql('"users"."created_at" ASC')) }, through: :licenses
  has_many :tokens, as: :bearer, dependent: :destroy
  has_many :releases, inverse_of: :product, dependent: :destroy
  has_many :release_platforms, through: :releases, source: :platform
  has_many :release_channels, through: :releases, source: :channel
  has_many :release_artifacts, inverse_of: :product
  has_one :role, as: :resource, dependent: :destroy

  after_create :set_role

  before_create -> { self.distribution_strategy = 'LICENSED' }, if: -> { distribution_strategy.nil? }

  validates :account, presence: { message: "must exist" }
  validates :name, presence: true
  validates :url, url: { protocols: %w[https http] }, allow_nil: true
  validates :metadata, length: { maximum: 64, message: "too many keys (exceeded limit of 64 keys)" }
  validates :distribution_strategy, inclusion: { in: DISTRIBUTION_STRATEGIES, message: "unsupported distribution strategy" }, allow_nil: true

  def licensed_distribution?
    # NOTE(ezekg) Backwards compat
    return true if
      distribution_strategy.nil?

    distribution_strategy == 'LICENSED'
  end

  def open_distribution?
    distribution_strategy == 'OPEN'
  end

  def closed_distribution?
    distribution_strategy == 'CLOSED'
  end

  private

  def set_role
    grant! :product
  end
end
