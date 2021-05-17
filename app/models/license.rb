# frozen_string_literal: true

class License < ApplicationRecord
  include Limitable
  include Tokenable
  include Pageable
  include Roleable
  include Searchable

  EXCLUDED_KEYS = %w[actions action].freeze

  SEARCH_ATTRIBUTES = %i[id key name metadata].freeze
  SEARCH_RELATIONSHIPS = {
    product: %i[id name],
    policy: %i[id name],
    user: %i[id email]
  }

  search attributes: SEARCH_ATTRIBUTES, relationships: SEARCH_RELATIONSHIPS

  belongs_to :account
  belongs_to :user
  belongs_to :policy
  has_many :license_entitlements, dependent: :delete_all
  has_many :policy_entitlements, through: :policy
  has_many :tokens, as: :bearer, dependent: :destroy
  has_many :machines, dependent: :delete_all
  has_one :product, through: :policy
  has_one :role, as: :resource, dependent: :destroy

  # Used for legacy encrypted licenses
  attr_reader :raw

  before_create :enforce_license_limit_on_account!
  before_create -> { self.protected = policy.protected? }, if: -> { policy.present? && protected.nil? }
  before_create :set_first_check_in, if: -> { policy.present? && requires_check_in? }
  before_create :set_expiry, if: -> { expiry.nil? && policy.present? }
  before_create :autogenerate_key, if: -> { key.nil? && policy.present? }
  before_create :crypt_key, if: -> { scheme? && !legacy_encrypted? }
  after_create :set_role

  validates :account, presence: { message: "must exist" }
  validates :policy,
    presence: { message: "must exist" },
    scope: { by: :account_id }

  # Validate this association only if we've been given a user (because it's optional)
  validates :user,
    presence: { message: "must exist" },
    scope: { by: :account_id },
    unless: -> { user_id.nil? }

  validate on: :create, if: -> { id_before_type_cast.present? } do
    errors.add :id, :invalid, message: 'must be a valid UUID' if
      !UUID_REGEX.match?(id_before_type_cast)

    errors.add :id, :conflict, message: 'must not conflict with another license' if
      account.licenses.exists?(id)
  end

  validate on: :create, unless: -> { policy.nil? } do
    errors.add :key, :conflict, message: "must not conflict with another license's identifier (UUID)" if key.present? && key =~ UUID_REGEX && account.licenses.exists?(key)

    # This is for our original "encrypted" keys only (legacy scheme)
    errors.add :key, :not_supported, message: "cannot be specified for a legacy encrypted license" if key.present? && legacy_encrypted?
  end

  validate on: :update do |license|
    next unless license.uses_changed?
    next if license&.uses.nil? || license.policy&.max_uses.nil?
    next if license.uses <= license.policy.max_uses

    license.errors.add :uses, :limit_exceeded, message: "usage exceeds maximum allowed by current policy (#{license.policy.max_uses})"
  end

  validates :key, length: { minimum: 1, maximum: 100.kilobytes }, uniqueness: { case_sensitive: true, scope: :account_id }, exclusion: { in: EXCLUDED_ALIASES, message: "is reserved" }, unless: -> { key.nil? }
  validates :metadata, length: { maximum: 64, message: "too many keys (exceeded limit of 64 keys)" }
  validates :uses, numericality: { greater_than_or_equal_to: 0 }

  # FIXME(ezekg) Hack to override pg_search with more performant queries
  # TODO(ezekg) Rip out pg_search completely
  scope :search_id, -> (term) {
    identifier = term.to_s
    return none if
      identifier.empty?

    return where(id: identifier) if
      UUID_REGEX.match?(identifier)

    where('id::text ILIKE ?', "%#{identifier}%")
  }

  scope :search_key, -> (term) {
    where('key ILIKE ?', "%#{term}%")
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

      scope.where('"licenses"."metadata" @> ?', before_type_cast.to_json)
        .or(
          scope.where('"licenses"."metadata" @> ?', after_type_cast.to_json)
        )
    end
  }

  scope :search_user, -> (term) {
    user_identifier = term.to_s
    return none if
      user_identifier.empty?

    return where(user_id: user_identifier) if
      UUID_REGEX.match?(user_identifier)

    tsv_query = <<~SQL
      to_tsvector('simple', users.id::text)
      @@
      to_tsquery(
        'simple',
        ''' ' ||
        ?     ||
        ' ''' ||
        ':*'
      )
    SQL

    joins(:user).where('users.email ILIKE ?', "%#{user_identifier}%")
                .or(
                  joins(:user).where(tsv_query.squish, user_identifier)
                )
  }

  scope :active, -> (start_date = 90.days.ago) { where 'created_at >= :start_date OR last_validated_at >= :start_date', start_date: start_date }
  scope :suspended, -> (status = true) { where suspended: ActiveRecord::Type::Boolean.new.cast(status) }
  scope :unassigned, -> (status = true) {
    if ActiveRecord::Type::Boolean.new.cast(status)
      where 'user_id IS NULL'
    else
      where 'user_id IS NOT NULL'
    end
  }
  scope :expired, -> (status = true) {
    if ActiveRecord::Type::Boolean.new.cast(status)
      where 'expiry IS NOT NULL AND expiry < ?', Time.current
    else
      where 'expiry IS NULL OR expiry >= ?', Time.current
    end
  }
  scope :with_metadata, -> (meta) { search_metadata meta }
  scope :for_policy, -> (id) { where policy: id }
  scope :for_user, -> (id) { where user: id }
  scope :for_product, -> (id) { joins(:policy).where policies: { product_id: id } }
  scope :for_machine, -> (id) { joins(:machines).where machines: { id: id } }
  scope :for_fingerprint, -> (fp) { joins(:machines).where machines: { fingerprint: fp } }

  delegate :requires_check_in?, to: :policy
  delegate :check_in_interval, to: :policy
  delegate :check_in_interval_count, to: :policy
  delegate :duration, to: :policy
  delegate :encrypted?, to: :policy
  delegate :legacy_encrypted?, to: :policy
  delegate :scheme?, to: :policy
  delegate :scheme, to: :policy
  delegate :pool?, to: :policy

  def entitlements
    entl = Entitlement.where(account_id: account_id).distinct

    entl.left_outer_joins(:policy_entitlements, :license_entitlements)
        .where(policy_entitlements: { policy_id: policy_id })
        .or(
          entl.where(license_entitlements: { license_id: id })
        )
  end

  def protected?
    return policy.protected? if protected.nil?

    protected
  end

  def suspended?
    suspended
  end

  def expired?
    return false if expiry.nil?

    expiry < Time.current
  end

  def active?(t = 90.days.ago)
    (created_at >= t || last_validated_at >= t) rescue false
  end

  def check_in_overdue?
    return false unless requires_check_in?

    last_check_in_at < check_in_interval_count.send(check_in_interval).ago
  rescue NoMethodError
    nil
  end

  def next_check_in_at
    return nil unless requires_check_in?

    last_check_in_at + check_in_interval_count.send(check_in_interval) rescue nil
  end

  def check_in!
    return false unless requires_check_in?

    self.last_check_in_at = Time.current
    save
  end

  def renew!
    return false if expiry.nil? || policy.duration.nil?

    self.expiry += policy.duration
    save
  end

  def suspend!
    self.suspended = true
    save
  end

  def reinstate!
    self.suspended = false
    save
  end

  private

  attr_accessor :seed_key

  def default_seed_key
    case scheme
    when "RSA_2048_PKCS1_ENCRYPT"
      JSON.generate(id: id, created: created_at, duration: duration, expiry: expiry)
    when "RSA_2048_JWT_RS256"
      claims = { jti: SecureRandom.uuid, iss: 'https://keygen.sh', aud: account.id, sub: id, iat: created_at.to_i, nbf: created_at.to_i }
      claims[:exp] = expiry.to_i if expiry.present?

      JSON.generate(claims)
    else
      JSON.generate(
        account: { id: account.id },
        product: { id: product.id },
        policy: { id: policy.id, duration: policy.duration },
        user: if user.present?
                { id: user.id, email: user.email }
              else
                nil
              end,
        license: {
          id: id,
          created: created_at,
          expiry: expiry,
        }
      )
    end
  end

  def set_role
    grant! :license
  end

  def set_first_check_in
    return if last_check_in_at.present?

    self.last_check_in_at = Time.current
  end

  def set_expiry
    if policy.duration.nil?
      self.expiry = nil
    else
      self.expiry = Time.current + ActiveSupport::Duration.build(policy.duration)
    end
  end

  def autogenerate_key
    return if key.present?

    # We need to define an ID and timestamps beforehand since they may
    # be used in an auto-generated key
    self.created_at = self.updated_at = Time.current
    self.id = SecureRandom.uuid if scheme?

    case
    when legacy_encrypted?
      generate_legacy_encrypted_key!
    when scheme?
      generate_seed_key!
    when pool?
      generate_pooled_key!
    else
      generate_unencrypted_key!
    end

    # We're raising a RecordInvalid exception so that the transaction will be
    # halted and rolled back (since our record is invalid without a key)
    raise ActiveRecord::RecordInvalid if key.nil?
  end

  # FIXME(ezekg) All of these callbacks need to be moved into a license key
  #              encryption/signing service
  def crypt_key
    return unless key.present?

    self.seed_key = key
    self.key = nil

    case scheme
    when "RSA_2048_PKCS1_ENCRYPT"
      generate_pkcs1_encrypted_key!
    when "RSA_2048_PKCS1_SIGN"
      generate_pkcs1_signed_key! version: 1
    when "RSA_2048_PKCS1_PSS_SIGN"
      generate_pkcs1_pss_signed_key! version: 1
    when "RSA_2048_JWT_RS256"
      generate_jwt_rs256_key!
    when "RSA_2048_PKCS1_SIGN_V2"
      generate_pkcs1_signed_key! version: 2
    when "RSA_2048_PKCS1_PSS_SIGN_V2"
      generate_pkcs1_pss_signed_key! version: 2
    when "ED25519_SIGN"
      generate_ed25519_signed_key!
    end

    raise ActiveRecord::RecordInvalid if key.nil?
  end

  def generate_seed_key!
    self.key = default_seed_key
  end

  def generate_pooled_key!
    if item = policy.pop!
      self.key = item.key
    else
      errors.add :policy, :pool_empty, message: "pool is empty"
    end
  end

  def generate_legacy_encrypted_key!
    @raw, enc = generate_hashed_token :key, version: "v1" do |token|
      # Replace first n characters with our id so that we can do a lookup
      # on the encrypted key
      token.gsub(/\A.{#{UUID_LENGTH}}/, id.delete("-"))
           .scan(/.{#{UUID_LENGTH}}/).join("-")
    end

    self.key = enc
  end

  def generate_unencrypted_key!
    self.key = generate_token :key, length: 16 do |token|
      # Split every n characters, e.g. XXXX-XXXX-XXXX
      token.scan(/.{1,6}/).join("-").upcase
    end
  end

  def generate_pkcs1_encrypted_key!
    if seed_key.bytesize > RSA_MAX_BYTE_SIZE
      errors.add :key, :byte_size_exceeded, message: "key exceeds maximum byte length (max size of #{RSA_MAX_BYTE_SIZE} bytes)"

      return
    end

    priv = OpenSSL::PKey::RSA.new account.private_key
    encrypted_key = priv.private_encrypt seed_key
    encoded_key = Base64.urlsafe_encode64 encrypted_key

    self.key = encoded_key
  end

  def generate_pkcs1_signed_key!(version:)
    priv = OpenSSL::PKey::RSA.new account.private_key
    res = nil

    case version
    when 1
      sig = priv.sign OpenSSL::Digest::SHA256.new, seed_key

      encoded_key = Base64.urlsafe_encode64 seed_key
      encoded_sig = Base64.urlsafe_encode64 sig

      res = "#{encoded_key}.#{encoded_sig}"
    when 2
      encoded_key = Base64.urlsafe_encode64 seed_key
      signing_data = "key/#{encoded_key}"
      sig = priv.sign OpenSSL::Digest::SHA256.new, signing_data
      encoded_sig = Base64.urlsafe_encode64 sig

      res = "#{signing_data}.#{encoded_sig}"
    end

    self.key = res
  end

  def generate_pkcs1_pss_signed_key!(version:)
    priv = OpenSSL::PKey::RSA.new account.private_key
    res = nil

    case version
    when 1
      sig = priv.sign_pss OpenSSL::Digest::SHA256.new, seed_key, salt_length: :max, mgf1_hash: "SHA256"

      encoded_key = Base64.urlsafe_encode64 seed_key
      encoded_sig = Base64.urlsafe_encode64 sig

      res = "#{encoded_key}.#{encoded_sig}"
    when 2
      encoded_key = Base64.urlsafe_encode64 seed_key
      signing_data = "key/#{encoded_key}"
      sig = priv.sign_pss OpenSSL::Digest::SHA256.new, signing_data, salt_length: :max, mgf1_hash: "SHA256"
      encoded_sig = Base64.urlsafe_encode64 sig

      res = "#{signing_data}.#{encoded_sig}"
    end

    self.key = res
  end

  def generate_jwt_rs256_key!
    priv = OpenSSL::PKey::RSA.new account.private_key
    payload = JSON.parse seed_key
    jwt = JWT.encode payload, priv, "RS256"

    self.key = jwt
  rescue JSON::GeneratorError,
         JSON::ParserError
    errors.add :key, :jwt_claims_invalid, message: "key is not a valid JWT claims payload (must be a valid JSON encoded string)"
  rescue JWT::InvalidPayload => e
    errors.add :key, :jwt_claims_invalid, message: "key is not a valid JWT claims payload (#{e.message})"
  end

  def generate_ed25519_signed_key!
    signing_key = Ed25519::SigningKey.new [account.ed25519_private_key].pack('H*')
    encoded_license_key = Base64.urlsafe_encode64 seed_key
    signing_data = "key/#{encoded_license_key}"
    sig = signing_key.sign signing_data
    encoded_sig = Base64.urlsafe_encode64 sig

    self.key = "#{signing_data}.#{encoded_sig}"
  end

  def enforce_license_limit_on_account!
    return unless account.trialing_or_free_tier?

    active_licensed_user_count = account.active_licensed_user_count
    active_licensed_user_limit =
      if account.trialing? && account.billing.card.present?
        account.plan.max_licenses || account.plan.max_users
      else
        50
      end

    return if active_licensed_user_count.nil? ||
              active_licensed_user_limit.nil?

    if active_licensed_user_count >= active_licensed_user_limit
      errors.add :account, :license_limit_exceeded, message: "Your tier's active licensed user limit of #{active_licensed_user_limit.to_s :delimited} has been reached for your account. Please upgrade to a paid tier and add a payment method at https://app.keygen.sh/billing."

      throw :abort
    end
  end
end
