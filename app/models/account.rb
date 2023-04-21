# frozen_string_literal: true

class Account < ApplicationRecord
  include ActiveModel::Validations
  include Welcomeable
  include Limitable
  include Orderable
  include Dirtyable
  include Pageable
  include Billable

  belongs_to :plan
  has_one :billing
  has_many :environments
  has_many :webhook_endpoints
  has_many :webhook_events
  has_many :request_logs
  has_many :metrics
  has_many :tokens
  has_many :users, index_errors: true
  has_many :second_factors
  has_many :products
  has_many :policies
  has_many :keys
  has_many :licenses
  has_many :machines
  has_many :machine_processes
  has_many :entitlements
  has_many :policy_entitlements
  has_many :license_entitlements
  has_many :releases
  has_many :release_platforms
  has_many :release_arches
  has_many :release_filetypes
  has_many :release_channels
  has_many :release_entitlement_constraints
  has_many :release_download_links
  has_many :release_upgrade_links
  has_many :release_upload_links
  has_many :release_artifacts
  has_many :event_logs
  has_many :groups
  has_many :group_owners

  accepts_nested_attributes_for :users, limit: 10
  tracks_nested_attributes_for :users

  encrypts :ed25519_private_key
  encrypts :private_key
  encrypts :secret_key

  before_validation :set_founding_users_roles!,
    if: :users_attributes_assigned?,
    on: :create

  before_create :set_autogenerated_registration_info!

  before_create -> { self.api_version ||= DEFAULT_API_VERSION }
  before_create -> { self.backend ||= 'R2' }
  before_create -> { self.slug = slug.downcase }

  before_create :generate_secret_key!
  before_create :generate_rsa_keys!
  before_create :generate_ed25519_keys!

  validates :users, length: { minimum: 1, message: "must have at least one admin user" }

  validates :slug, uniqueness: { case_sensitive: false }, format: { with: /\A[-a-z0-9]+\z/, message: "can only contain lowercase letters, numbers and dashes" }, length: { maximum: 255 }, exclusion: { in: EXCLUDED_ALIASES, message: "is reserved" }, unless: -> { slug.nil? }

  validates :api_version,
    allow_nil: true,
    inclusion: {
      message: 'unsupported version',
      in: RequestMigrations.supported_versions,
    }

  validate on: [:create, :update] do
    clean_slug = "#{slug}".tr "-", ""
    errors.add :slug, :not_allowed, message: "cannot resemble a UUID" if clean_slug =~ UUID_RE
  end

  scope :active, -> (with_activity_from: 90.days.ago) {
    joins(:billing)
      .where(billings: { state: %i[subscribed trialing pending] })
      .where(<<~SQL.squish, with_activity_from)
        EXISTS (
          SELECT
            1
          FROM
            "event_logs"
          WHERE
            "event_logs"."account_id" = "accounts"."id" AND
            "event_logs"."created_at" > ?
          LIMIT
            1
        )
      SQL
  }
  scope :paid, -> { joins(:plan, :billing).where(plan: Plan.paid, billings: { state: 'subscribed' }) }
  scope :free, -> { joins(:plan, :billing).where(plan: Plan.free, billings: { state: 'subscribed' }) }
  scope :ent,  -> { joins(:plan, :billing).where(plan: Plan.ent, billings: { state: 'subscribed' }) }
  scope :with_plan, -> (id) { where plan: id }

  after_commit :clear_cache!,
    on: %i[update destroy]

  def billing!
    raise Keygen::Error::NotFoundError.new(model: Billing.name) unless
      billing.present?

    billing
  end

  def email
    admins.first.email
  end

  # TODO(ezekg) Temp attributes for backwards compat during DSA/ECDSA deploy
  def private_key
    attrs = attributes

    case
    when attrs.key?("rsa_private_key")
      attrs["rsa_private_key"]
    when attrs.key?("private_key")
      attrs["private_key"]
    end
  end

  def private_key=(value)
    attrs = attributes

    case
    when attrs.key?("rsa_private_key")
      write_attribute :rsa_private_key, value
    when attrs.key?("private_key")
      write_attribute :private_key, value
    end
  end

  def public_key
    attrs = attributes

    case
    when attrs.key?("rsa_public_key")
      attrs["rsa_public_key"]
    when attrs.key?("public_key")
      attrs["public_key"]
    end
  end

  def public_key=(value)
    attrs = attributes

    case
    when attrs.key?("rsa_public_key")
      write_attribute :rsa_public_key, value
    when attrs.key?("public_key")
      write_attribute :public_key, value
    end
  end

  def self.cache_key(id)
    [:accounts, id, CACHE_KEY_VERSION].join ":"
  end

  def cache_key
    Account.cache_key id
  end

  def self.clear_cache!(id)
    key = Account.cache_key id

    Rails.cache.delete key
  end

  def clear_cache!
    Account.clear_cache! id
    Account.clear_cache! slug
  end

  def self.daily_request_count_cache_key_ts
    now = Time.current

    now.beginning_of_day.to_i
  end

  def self.daily_request_count_cache_key(id)
    [:req, :limits, :daily, id, daily_request_count_cache_key_ts].join ':'
  end

  def daily_request_count_cache_key
    Account.daily_request_count_cache_key id
  end

  def daily_request_count=(count)
    Rails.cache.write daily_request_count_cache_key, count, raw: true
  end

  def daily_request_count
    count = Rails.cache.read daily_request_count_cache_key, raw: true

    count.to_i
  end

  def daily_request_limit
    return 2_500 if billing&.trialing? && billing&.card.nil?

    plan&.max_reqs
  end

  def daily_request_limit_exceeded?
    return false if daily_request_limit.nil?

    daily_request_count > daily_request_limit
  end

  def active_licensed_user_count
    license_counts =
      self.licenses.active
        .reorder(Arel.sql('"licenses"."user_id" NULLS FIRST'))
        .group(Arel.sql('"licenses"."user_id"'))
        .count

    # FIXME(ezekg) The nil key here is really weird, but that's what AR gives us for
    #              unassigned licenses i.e. those without a user.
    total_unassigned_licenses = license_counts[nil].to_i

    # We're counting a user with any amount of licenses as 1 "licensed user."
    total_assigned_licenses = license_counts.except(nil).count

    total_licensed_users =
      total_unassigned_licenses + total_assigned_licenses

    total_licensed_users
  end

  def trialing_or_free?
    return true if billing.nil?

    return (billing.trialing? && billing.card.nil?) ||
            plan.free?
  end

  def free?
    return false if billing.nil?

    plan.free?
  end

  def paid?
    return false if billing.nil?

    return (billing.active? || billing.card.present?) &&
           plan.paid?
  end

  def ent?
    return false if billing.nil?

    return plan.ent?
  end

  def protected?
    protected
  end

  def status
    billing&.state&.upcase
  end

  def admins
    users.admins
  end

  def technical_contacts
    users.with_roles(:admin, :developer)
  end

  def self.associated_to?(association)
    associations = self.reflect_on_all_associations(:has_many)

    associations.any? { |r| r.name == association.to_sym }
  end

  def associated_to?(association)
    self.class.associated_to?(association)
  end

  private

  def set_founding_users_roles!
    users.each do |user|
      next unless
        user.new_record?

      user.assign_attributes(
        role_attributes: { name: :admin },
      )
    end
  end

  def set_autogenerated_registration_info!
    parsed_email = users.first.parsed_email
    throw :abort if parsed_email.nil?

    user = parsed_email.fetch(:user)
    host = parsed_email.fetch(:host)

    autogen_slug = slug || host.parameterize.dasherize.downcase
    autogen_name = host

    # Generate an account slug using the email if the current domain is a public
    # email service or if an account with the domain already exists
    if PUBLIC_EMAIL_DOMAINS.include?(host)
      autogen_slug = user.parameterize.dasherize.downcase
      autogen_name = user
    end

    # FIXME(ezekg) Duplicate slug validation (name may be a UUID)
    if autogen_slug =~ UUID_RE
      errors.add :slug, :not_allowed, message: "cannot resemble a UUID"

      throw :abort
    end

    # Append a random string if slug is taken for public email service.
    # Otherwise, don't allow duplicate accounts for taken domains.
    if Account.exists?(slug: autogen_slug)
      if PUBLIC_EMAIL_DOMAINS.include?(host)
        autogen_slug += "-#{SecureRandom.hex(4)}"
      else
        errors.add :slug, :not_allowed, message: "already exists for this domain (please choose a different value or use account recovery)"

        throw :abort
      end
    end

    self.name = autogen_name unless name.present?
    self.slug = autogen_slug
  end

  def generate_secret_key!
    self.secret_key = SecureRandom.hex 64
  end
  alias_method :regenerate_secret_key!, :generate_secret_key!

  def generate_rsa_keys!
    priv = if private_key.nil?
             OpenSSL::PKey::RSA.generate RSA_KEY_SIZE
           else
             OpenSSL::PKey::RSA.new private_key
           end
    pub = priv.public_key

    # TODO(ezekg) Rename to rsa_private_key and rsa_public_key
    self.private_key = priv.to_pem
    self.public_key = pub.to_pem
  end
  alias_method :regenerate_rsa_keys!, :generate_rsa_keys!

  def generate_ed25519_keys!
    priv =
      if ed25519_private_key.present?
        Ed25519::SigningKey.new([ed25519_private_key].pack("H*"))
      else
        Ed25519::SigningKey.generate
      end
    pub = priv.verify_key

    self.ed25519_private_key = priv.to_bytes.unpack1("H*")
    self.ed25519_public_key = pub.to_bytes.unpack1("H*")
  end
  alias_method :regenerate_ed25519_keys!, :generate_ed25519_keys!
end
