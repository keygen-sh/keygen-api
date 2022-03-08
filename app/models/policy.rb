# frozen_string_literal: true

class Policy < ApplicationRecord
  include Limitable
  include Orderable
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

  TRANSFER_STRATEGIES = %w[
    RESET_EXPIRY
    KEEP_EXPIRY
  ]

  AUTHENTICATION_STRATEGIES = %w[
    TOKEN
    LICENSE
    MIXED
    NONE
  ].freeze

  HEARTBEAT_CULL_STRATEGIES = %w[
    DEACTIVATE_DEAD
    KEEP_DEAD
  ]

  HEARTBEAT_RESURRECTION_STRATEGIES = %w[
    ALWAYS_REVIVE
    15_MINUTE_REVIVE
    10_MINUTE_REVIVE
    5_MINUTE_REVIVE
    2_MINUTE_REVIVE
    1_MINUTE_REVIVE
    NO_REVIVE
  ]

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
  before_create -> { self.transfer_strategy = 'KEEP_EXPIRY' }, if: -> { heartbeat_resurrection_strategy.nil? }
  before_create -> { self.authentication_strategy = 'TOKEN' }, if: -> { authentication_strategy.nil? }
  before_create -> { self.heartbeat_cull_strategy = 'DEACTIVATE_DEAD' }, if: -> { heartbeat_cull_strategy.nil? }
  before_create -> { self.heartbeat_resurrection_strategy = 'NO_REVIVE' }, if: -> { heartbeat_resurrection_strategy.nil? }
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
  validates :authentication_strategy,
    inclusion: { in: AUTHENTICATION_STRATEGIES, message: "unsupported authentication strategy" },
    allow_nil: true

  validates :heartbeat_cull_strategy,
    inclusion: { in: HEARTBEAT_CULL_STRATEGIES, message: "unsupported heartbeat cull strategy" },
    allow_nil: true

  validates :heartbeat_cull_strategy, inclusion: { in: %w[KEEP_DEAD], message: 'incompatible heartbeat cull strategy (must be KEEP_DEAD when resurrection strategy is ALWAYS_REVIVE)' },
    if: :always_resurrect_dead_machines?

  validates :heartbeat_resurrection_strategy,
    inclusion: { in: HEARTBEAT_RESURRECTION_STRATEGIES, message: 'unsupported heartbeat resurrection strategy' },
    allow_nil: true

  validates :transfer_strategy,
    inclusion: { in: TRANSFER_STRATEGIES, message: 'unsupported transfer strategy' },
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
    # NOTE(ezekg) Backwards compat
    return true if
      heartbeat_cull_strategy.nil?

    heartbeat_cull_strategy == 'DEACTIVATE_DEAD'
  end

  def keep_dead_machines?
    heartbeat_cull_strategy == 'KEEP_DEAD'
  end

  def resurrect_dead_machines?
    # NOTE(ezekg) Backwards compat
    return false if
      heartbeat_resurrection_strategy.nil?

    heartbeat_resurrection_strategy != 'NO_REVIVE'
  end

  def always_resurrect_dead_machines?
    heartbeat_resurrection_strategy == 'ALWAYS_REVIVE'
  end

  def lazarus_ttl
    ttl = case heartbeat_resurrection_strategy
          when '15_MINUTE_REVIVE'
            15.minutes
          when '10_MINUTE_REVIVE'
            10.minutes
          when '5_MINUTE_REVIVE'
            5.minutes
          when '2_MINUTE_REVIVE'
            2.minutes
          when '1_MINUTE_REVIVE'
            1.minute
          else
            nil
          end

    ttl.to_i
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
      authentication_strategy.nil?

    authentication_strategy == 'TOKEN' || supports_mixed_auth?
  end

  def supports_license_auth?
    authentication_strategy == 'LICENSE' || supports_mixed_auth?
  end

  def supports_mixed_auth?
    authentication_strategy == 'MIXED'
  end

  def supports_auth?
    authentication_strategy != 'NONE'
  end

  def reset_expiry_on_transfer?
    transfer_strategy == 'RESET_EXPIRY'
  end

  def keep_expiry_on_transfer?
    # NOTE(ezekg) Backwards compat
    return true if
      transfer_strategy.nil?

    transfer_strategy == 'KEEP_EXPIRY'
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
