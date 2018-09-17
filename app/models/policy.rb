class Policy < ApplicationRecord
  include Limitable
  include Pageable
  include Searchable

  CRYPTO_SCHEMES = %w[
    LEGACY_ENCRYPT
    RSA_2048_PKCS1_ENCRYPT
    RSA_2048_PKCS1_SIGN
    RSA_2048_PKCS1_PSS_SIGN
    RSA_2048_JWT_RS256
  ].freeze

  SEARCH_ATTRIBUTES = %i[id name metadata].freeze
  SEARCH_RELATIONSHIPS = {
    product: %i[id name]
  }.freeze

  search attributes: SEARCH_ATTRIBUTES, relationships: SEARCH_RELATIONSHIPS

  belongs_to :account
  belongs_to :product
  has_many :licenses, dependent: :destroy
  has_many :pool, class_name: "Key", dependent: :destroy

  # Default to legacy encryption scheme so that we don't break backwards compat
  before_validation -> { self.scheme = 'LEGACY_ENCRYPT' }, on: :create, if: -> { encrypted? && scheme.nil? }
  before_create -> { self.protected = account.protected? }, if: -> { protected.nil? }

  validates :account, presence: { message: "must exist" }
  validates :product, presence: { message: "must exist" }

  validates :name, presence: true
  validates :max_machines, numericality: { greater_than_or_equal_to: 1, message: "must be greater than or equal to 1 for floating policy" }, allow_nil: true, if: :floating?
  validates :max_machines, numericality: { equal_to: 1, message: "must be equal to 1 for non-floating policy" }, allow_nil: true, if: :node_locked?
  validates :duration, numericality: { greater_than_or_equal_to: 1.day.to_i, message: "must be greater than or equal to 86400 (1 day)" }, allow_nil: true
  validates :check_in_interval, inclusion: { in: %w[day week month year], message: "must be one of: day, week, month, year" }, if: :requires_check_in?
  validates :check_in_interval_count, inclusion: { in: 1..365, message: "must be a number between 1 and 365 inclusive" }, if: :requires_check_in?
  validates :metadata, length: { maximum: 64, message: "too many keys (exceeded limit of 64 keys)" }
  validates :scheme, inclusion: { in: %w[LEGACY_ENCRYPT], message: "unsupported encryption scheme (scheme must be LEGACY_ENCRYPT for legacy encrypted policies)" }, if: :encrypted?
  validates :scheme, inclusion: { in: CRYPTO_SCHEMES, message: "unsupported encryption scheme" }, if: :scheme?

  validate do
    errors.add :encrypted, :not_supported, message: "cannot be encrypted and use a pool" if pool? && encrypted?
    errors.add :scheme, :not_supported, message: "cannot use a scheme and use a pool" if pool? && scheme?
    errors.add :scheme, :invalid, message: "must be encrypted when using LEGACY_ENCRYPT scheme" if !encrypted? && legacy_scheme?
  end

  scope :product, -> (id) { where product: id }

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

  def pop!
    return nil if pool.empty?
    key = pool.first.destroy
    return key
  rescue ActiveRecord::StaleObjectError
    reload
    retry
  end
end
