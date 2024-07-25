# frozen_string_literal: true

class ReleasePackage < ApplicationRecord
  include Keygen::PortableClass
  include Environmental
  include Accountable
  include Limitable
  include Orderable
  include Pageable
  include Diffable

  belongs_to :product,
    inverse_of: :release_packages
  belongs_to :engine,
    foreign_key: :release_engine_id,
    class_name: 'ReleaseEngine',
    autosave: true,
    optional: true
  has_many :releases,
    inverse_of: :package,
    dependent: :destroy_async
  has_many :artifacts,
    through: :releases,
    source: :artifacts

  has_environment default: -> { product&.environment_id }
  has_account default: -> { product&.account_id }, inverse_of: :release_packages

  accepts_nested_attributes_for :engine

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

  scope :for_user, -> user {
    joins(product: %i[licenses])
      .reorder(created_at: DEFAULT_SORT_ORDER)
      .where(
        product: { distribution_strategy: ['LICENSED', nil] },
        licenses: { id: License.for_user(user) },
      )
      .distinct
      .union(open)
      .reorder(
        created_at: DEFAULT_SORT_ORDER,
      )
  }

  scope :for_license, -> id {
    joins(product: %i[licenses])
      .reorder(created_at: DEFAULT_SORT_ORDER)
      .where(
        product: { distribution_strategy: ['LICENSED', nil] },
        licenses: { id: },
      )
      .union(open)
      .reorder(
        created_at: DEFAULT_SORT_ORDER,
      )
  }

  scope :licensed, -> { joins(:product).where(product: { distribution_strategy: ['LICENSED', nil] }) }
  scope :open,     -> { joins(:product).where(product: { distribution_strategy: 'OPEN' }) }
  scope :closed,   -> { joins(:product).where(product: { distribution_strategy: 'CLOSED' }) }

  scope :for_engine, -> engine {
    case engine
    when ReleaseEngine,
         UUID_RE
      joins(:engine).where(engine: { id: engine })
    else
      joins(:engine).where(engine: { key: engine.to_s })
    end
  }

  scope :for_engine_key, -> key { joins(:engine).where(release_engines: { key: }) }
  scope :pypi,           ->     { for_engine_key('pypi') }
  scope :tauri,          ->     { for_engine_key('tauri') }

  def engine_id? = release_engine_id?
  def engine_id  = release_engine_id
  def engine_id=(id)
    self.release_engine_id = id
  end

  private

  def validate_associated_records_for_engine
    return unless
      engine.present? && account.present?

    # Clear engine if the key is empty e.g. "" or nil
    return self.engine = nil unless
      engine.key?

    # FIXME(ezekg) Performing a safe create_or_find_by so we don't poison
    #              our current transaction by using DB exceptions
    rows = ReleaseEngine.find_by_sql [<<~SQL.squish, { account_id:, key: engine.key.downcase.strip.presence }]
      WITH ins AS (
        INSERT INTO "release_engines"
          (
            "account_id",
            "key",
            "created_at",
            "updated_at"
          )
        VALUES
          (
            :account_id,
            :key,
            current_timestamp(6),
            current_timestamp(6)
          )
        ON CONFLICT ("account_id", "key")
          DO NOTHING
        RETURNING
          *
      )
      SELECT
        *
      FROM
        ins

      UNION

      SELECT
        *
      FROM
        "release_engines"
      WHERE
        "release_engines"."account_id" = :account_id AND
        "release_engines"."key"        = :key
    SQL

    self.engine = rows.first
  end
end
