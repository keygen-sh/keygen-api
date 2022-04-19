# frozen_string_literal: true

class Product < ApplicationRecord
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

  belongs_to :account
  has_one :role, as: :resource, dependent: :destroy
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
  has_many :event_logs,
    as: :resource

  after_create :set_role

  before_create -> { self.distribution_strategy = 'LICENSED' }, if: -> { distribution_strategy.nil? }

  validates :name, presence: true
  validates :url, url: { protocols: %w[https http] }, allow_nil: true
  validates :metadata, length: { maximum: 64, message: "too many keys (exceeded limit of 64 keys)" }
  validates :distribution_strategy, inclusion: { in: DISTRIBUTION_STRATEGIES, message: "unsupported distribution strategy" }, allow_nil: true

  scope :search_id, -> (term) {
    identifier = term.to_s
    return none if
      identifier.empty?

    return where(id: identifier) if
      UUID_RX.match?(identifier)

    where('products.id::text ILIKE ?', "%#{identifier}%")
  }

  scope :search_name, -> (term) {
    where('products.name ILIKE ?', "%#{term}%")
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
