# frozen_string_literal: true

class Policy < ApplicationRecord
  include Limitable
  include Pageable
  include Diffable

  CRYPTO_SCHEMES = %w[
    LEGACY_ENCRYPT
    RSA_2048_PKCS1_ENCRYPT
    RSA_2048_PKCS1_SIGN
    RSA_2048_PKCS1_PSS_SIGN
    RSA_2048_JWT_RS256
    RSA_2048_PKCS1_SIGN_V2
    RSA_2048_PKCS1_PSS_SIGN_V2
    ED25519_SIGN
  ].freeze

  FINGERPRINT_UNIQUENESS_STRATEGIES = %w[
    UNIQUE_PER_ACCOUNT
    UNIQUE_PER_PRODUCT
    UNIQUE_PER_POLICY
    UNIQUE_PER_LICENSE
  ].freeze

  FINGERPRINT_MATCHING_STRATEGIES = %w[
    MATCH_ANY
    MATCH_MOST
    MATCH_ALL
  ].freeze

  EXPIRATION_STRATEGIES = %w[
    RESTRICT_ACCESS
    REVOKE_ACCESS
  ].freeze

  EXPIRATION_BASES = %w[
    FROM_CREATION
    FROM_FIRST_VALIDATION
    FROM_FIRST_ACTIVATION
    FROM_FIRST_DOWNLOAD
    FROM_FIRST_USE
  ].freeze

  LICENSE_AUTH_STRATEGIES = %w[
    TOKEN
    KEY
    MIXED
    NONE
  ].freeze

  belongs_to :account
  belongs_to :product
  has_many :licenses, dependent: :destroy
  has_many :machines, through: :licenses
  has_many :pool, class_name: "Key", dependent: :destroy
  has_many :policy_entitlements, dependent: :delete_all
  has_many :entitlements, through: :policy_entitlements
  has_many :event_logs,
    as: :resource

  # Default to legacy encryption scheme so that we don't break backwards compat
  before_validation -> { self.scheme = 'LEGACY_ENCRYPT' }, on: :create, if: -> { encrypted? && scheme.nil? }

  before_create -> { self.fingerprint_uniqueness_strategy = 'UNIQUE_PER_LICENSE' }, if: -> { fingerprint_uniqueness_strategy.nil? }
  before_create -> { self.fingerprint_matching_strategy = 'MATCH_ANY' }, if: -> { fingerprint_matching_strategy.nil? }
  before_create -> { self.expiration_strategy = 'RESTRICT_ACCESS' }, if: -> { expiration_strategy.nil? }
  before_create -> { self.expiration_basis = 'FROM_CREATION' }, if: -> { expiration_basis.nil? }
  before_create -> { self.license_auth_strategy = 'TOKEN' }, if: -> { license_auth_strategy.nil? }
  before_create -> { self.protected = account.protected? }, if: -> { protected.nil? }
  before_create -> { self.max_machines = 1 }, if: :node_locked?

  validates :account, presence: { message: "must exist" }
  validates :product,
    presence: { message: "must exist" },
    scope: { by: :account_id }

  validates :name, presence: true
  validates :duration, numericality: { greater_than: 0, less_than_or_equal_to: 2_147_483_647 }, allow_nil: true, allow_blank: true
  validates :duration, numericality: { greater_than_or_equal_to: 1.day.to_i, message: "must be greater than or equal to 86400 (1 day)" }, allow_nil: true
  validates :heartbeat_duration, numericality: { greater_than: 0, less_than_or_equal_to: 2_147_483_647 }, allow_nil: true, allow_blank: true
  validates :heartbeat_duration, numericality: { greater_than_or_equal_to: 2.minutes.to_i, message: "must be greater than or equal to 120 (2 minutes)" }, allow_nil: true
  validates :max_machines, numericality: { greater_than_or_equal_to: 0, less_than_or_equal_to: 2_147_483_647 }, allow_nil: true, allow_blank: true
  validates :max_machines, numericality: { greater_than_or_equal_to: 1, message: "must be greater than or equal to 1 for floating policy" }, allow_nil: true, if: :floating?
  validates :max_machines, numericality: { equal_to: 1, message: "must be equal to 1 for non-floating policy" }, allow_nil: true, if: :node_locked?
  validates :max_cores, numericality: { greater_than_or_equal_to: 1, less_than_or_equal_to: 2_147_483_647 }, allow_nil: true
  validates :max_uses, numericality: { greater_than_or_equal_to: 0, less_than_or_equal_to: 2_147_483_647 }, allow_nil: true, allow_blank: true
  validates :check_in_interval, inclusion: { in: %w[day week month year], message: "must be one of: day, week, month, year" }, if: :requires_check_in?
  validates :check_in_interval_count, inclusion: { in: 1..365, message: "must be a number between 1 and 365 inclusive" }, if: :requires_check_in?
  validates :metadata, length: { maximum: 64, message: "too many keys (exceeded limit of 64 keys)" }
  validates :scheme, inclusion: { in: %w[LEGACY_ENCRYPT], message: "unsupported encryption scheme (scheme must be LEGACY_ENCRYPT for legacy encrypted policies)" }, if: :encrypted?
  validates :scheme, inclusion: { in: CRYPTO_SCHEMES, message: "unsupported encryption scheme" }, if: :scheme?
  validates :fingerprint_uniqueness_strategy, inclusion: { in: FINGERPRINT_UNIQUENESS_STRATEGIES, message: "unsupported fingerprint uniqueness strategy" }, allow_nil: true
  validates :fingerprint_matching_strategy, inclusion: { in: FINGERPRINT_MATCHING_STRATEGIES, message: "unsupported fingerprint matching strategy" }, allow_nil: true
  validates :expiration_strategy, inclusion: { in: EXPIRATION_STRATEGIES, message: "unsupported expiration strategy" }, allow_nil: true
  validates :expiration_basis, inclusion: { in: EXPIRATION_BASES, message: "unsupported expiration basis" }, allow_nil: true
  validates :license_auth_strategy,
    inclusion: { in: LICENSE_AUTH_STRATEGIES, message: "unsupported authentication strategy" },
    allow_nil: true

  validate do
    errors.add :encrypted, :not_supported, message: "cannot be encrypted and use a pool" if pool? && encrypted?
    errors.add :scheme, :not_supported, message: "cannot use a scheme and use a pool" if pool? && scheme?
    errors.add :scheme, :invalid, message: "must be encrypted when using LEGACY_ENCRYPT scheme" if !encrypted? && legacy_scheme?
  end

  scope :search_id, -> (term) {
    identifier = term.to_s
    return none if
      identifier.empty?

    return where(id: identifier) if
      UUID_REGEX.match?(identifier)

    where('policies.id::text ILIKE ?', "%#{identifier}%")
  }

  scope :search_name, -> (term) {
    where('policies.name ILIKE ?', "%#{term}%")
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

      scope.where('policies.metadata @> ?', before_type_cast.to_json)
        .or(
          scope.where('policies.metadata @> ?', after_type_cast.to_json)
        )
    end
  }

  scope :search_product, -> (term) {
    product_identifier = term.to_s
    return none if
      product_identifier.empty?

    return where(product_id: product_identifier) if
      UUID_REGEX.match?(product_identifier)

    tsv_query = <<~SQL
      to_tsvector('simple', products.id::text)
      @@
      to_tsquery(
        'simple',
        ''' ' ||
        ?     ||
        ' ''' ||
        ':*'
      )
    SQL

    joins(:product)
      .where('products.name ILIKE ?', "%#{product_identifier}%")
      .or(
        joins(:product).where(tsv_query.squish, product_identifier)
      )
  }

  scope :for_product, -> (id) { where product: id }

  def pool?
    use_pool
  end

  def strict?
    strict
  end

  def floating?
    floating
  end

  def node_locked?
    !floating
  end

  def encrypted?
    encrypted
  end

  def scheme?
    scheme.present?
  end

  def legacy_encrypted?
    encrypted? && legacy_scheme?
  end

  def legacy_scheme?
    scheme == 'LEGACY_ENCRYPT'
  end

  def protected?
    protected
  end

  def requires_check_in?
    require_check_in
  end

  def deactivate_dead_machines?
    true
  end

  def fingerprint_uniq_per_account?
    fingerprint_uniqueness_strategy == 'UNIQUE_PER_ACCOUNT'
  end

  def fingerprint_uniq_per_product?
    fingerprint_uniqueness_strategy == 'UNIQUE_PER_PRODUCT'
  end

  def fingerprint_uniq_per_policy?
    fingerprint_uniqueness_strategy == 'UNIQUE_PER_POLICY'
  end

  def fingerprint_uniq_per_license?
    return true if fingerprint_uniqueness_strategy.nil? # NOTE(ezekg) Backwards compat

    fingerprint_uniqueness_strategy == 'UNIQUE_PER_LICENSE'
  end

  def fingerprint_match_any?
    return true if fingerprint_matching_strategy.nil? # NOTE(ezekg) Backwards compat

    fingerprint_matching_strategy == 'MATCH_ANY'
  end

  def fingerprint_match_most?
    fingerprint_matching_strategy == 'MATCH_MOST'
  end

  def fingerprint_match_all?
    fingerprint_matching_strategy == 'MATCH_ALL'
  end

  def restrict_access?
    expiration_strategy == 'RESTRICT_ACCESS'
  end

  def revoke_access?
    # NOTE(ezekg) Backwards compat
    return true if
      expiration_strategy.nil?

    expiration_strategy == 'REVOKE_ACCESS'
  end

  def expire_from_creation?
    # NOTE(ezekg) Backwards compat
    return true if
      expiration_basis.nil?

    expiration_basis == 'FROM_CREATION'
  end

  def expire_from_first_validation?
    expiration_basis == 'FROM_FIRST_VALIDATION'
  end

  def expire_from_first_activation?
    expiration_basis == 'FROM_FIRST_ACTIVATION'
  end

  def expire_from_first_use?
    expiration_basis == 'FROM_FIRST_USE'
  end

  def expire_from_first_download?
    expiration_basis == 'FROM_FIRST_DOWNLOAD'
  end

  def supports_token_auth?
    # NOTE(ezekg) Backwards compat
    return true if
     license_auth_strategy.nil?

    license_auth_strategy == 'TOKEN' || supports_mixed_auth?
  end

  def supports_key_auth?
    license_auth_strategy == 'KEY' || supports_mixed_auth?
  end

  def supports_mixed_auth?
    license_auth_strategy == 'MIXED'
  end

  def supports_auth?
    license_auth_strategy != 'NONE'
  end

  def pop!
    return nil if pool.empty?
    key = pool.first.destroy
    return key
  rescue ActiveRecord::StaleObjectError
    reload
    retry
  end
end
