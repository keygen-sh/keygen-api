# frozen_string_literal: true

class Product < ApplicationRecord
  include Environmental
  include Limitable
  include Orderable
  include Pageable
  include Roleable
  include Diffable

  DISTRIBUTION_STRATEGIES = %w[
    LICENSED
    OPEN
    CLOSED
  ]

  DISTRIBUTION_ENGINES = %w[
    PYPI
  ]

  belongs_to :account
  has_many :policies, dependent: :destroy_async
  has_many :keys, through: :policies, source: :pool
  has_many :licenses, through: :policies
  has_many :machines, -> { distinct.reorder(created_at: DEFAULT_SORT_ORDER) }, through: :licenses
  has_many :users, -> { distinct.reorder(created_at: DEFAULT_SORT_ORDER) }, through: :licenses
  has_many :tokens, as: :bearer, dependent: :destroy_async
  has_many :releases, inverse_of: :product, dependent: :destroy_async
  has_many :release_channels, through: :releases, source: :channel
  has_many :release_artifacts, through: :releases, source: :artifacts
  has_many :release_platforms, through: :release_artifacts, source: :platform
  has_many :release_arches, through: :release_artifacts, source: :arch
  has_many :event_logs,
    as: :resource

  has_environment
  has_role :product
  has_permissions Permission::PRODUCT_PERMISSIONS

  before_create -> { self.distribution_strategy = 'LICENSED' }, if: -> { distribution_strategy.nil? }

  validates :code, length: { minimum: 1, maximum: 255 }, uniqueness: { case_sensitive: false, scope: :account_id }, allow_nil: true
  validates :name, presence: true
  validates :url, url: { protocols: %w[https http] }, allow_nil: true
  validates :metadata, length: { maximum: 64, message: "too many keys (exceeded limit of 64 keys)" }
  validates :distribution_strategy, inclusion: { in: DISTRIBUTION_STRATEGIES, message: "unsupported distribution strategy" }, allow_nil: true
  validates :distribution_engine, inclusion: { in: DISTRIBUTION_ENGINES, message: "unsupported distribution engine" }, allow_nil: true

  scope :search_id, -> (term) {
    identifier = term.to_s
    return none if
      identifier.empty?

    return where(id: identifier) if
      UUID_RE.match?(identifier)

    where('products.id::text ILIKE ?', "%#{sanitize_sql_like(identifier)}%")
  }

  scope :search_name, -> (term) {
    return none if
      term.blank?

    where('products.name ILIKE ?', "%#{sanitize_sql_like(term)}%")
  }

  scope :search_metadata, -> (terms) {
    # FIXME(ezekg) Duplicated code for licenses, users, and machines.
    # FIXME(ezekg) Need to figure out a better way to do this. We need to be able
    #              to search for the original string values and type cast, since
    #              HTTP querystring parameters are strings.
    #
    #              Example we need to be able to search for:
    #
    #                { metadata: { external_id: "1624214616", internal_id: 1 } }
    #
    terms.reduce(self) do |scope, (key, value)|
      search_key       = key.to_s.underscore.parameterize(separator: '_')
      before_type_cast = { search_key => value }
      after_type_cast  =
        case value
        when 'true'
          { search_key => true }
        when 'false'
          { search_key => false }
        when 'null'
          { search_key => nil }
        when /^\d+$/
          { search_key => value.to_i }
        when /^\d+\.\d+$/
          { search_key => value.to_f }
        else
          { search_key => value }
        end

      scope.where('products.metadata @> ?', before_type_cast.to_json)
        .or(
          scope.where('products.metadata @> ?', after_type_cast.to_json)
        )
    end
  }

  scope :for_product, -> id {
    where(id:)
  }

  scope :for_license, -> id {
    joins(:licenses).where(licenses: { id: })
                    .licensed
                    .distinct
                    .union(
                      self.open,
                    )
  }

  scope :for_user, -> id {
    joins(:users).where(users: { id: })
                 .licensed
                 .distinct
                 .union(
                   self.open,
                 )
  }

  scope :open,     -> { where(distribution_strategy: 'OPEN') }
  scope :licensed, -> { where(distribution_strategy: 'LICENSED') }
  scope :closed,   -> { where(distribution_strategy: 'CLOSED') }

  scope :pypi, -> { where(distribution_engine: 'PYPI') }

  def licensed? = distribution_strategy.nil? || distribution_strategy == 'LICENSED'
  def closed?   = distribution_strategy == 'CLOSED'
  def open?     = distribution_strategy == 'OPEN'
end
