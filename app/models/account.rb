# frozen_string_literal: true

class Account < ApplicationRecord
  include ActiveModel::Validations
  include Welcomeable
  include Sluggable
  include Limitable
  include Pageable
  include Billable

  sluggable attributes: %i[id slug], scope: -> (s) { s.includes :billing }

  belongs_to :plan
  has_many :webhook_endpoints, dependent: :destroy
  has_many :webhook_events, dependent: :destroy
  has_many :request_logs, dependent: :destroy
  has_many :metrics, dependent: :destroy
  has_many :tokens, dependent: :destroy
  has_many :users, index_errors: true, dependent: :destroy
  has_many :products, dependent: :destroy
  has_many :policies, dependent: :destroy
  has_many :keys, dependent: :destroy
  has_many :licenses, dependent: :destroy
  has_many :machines, dependent: :destroy
  has_one :billing, dependent: :destroy

  accepts_nested_attributes_for :users

  before_create -> { self.slug = slug.downcase }
  before_create :generate_secret_key!
  before_create :generate_rsa_keys!
  before_create :generate_dsa_keys!
  before_create :generate_ecdsa_keys!

  before_create :set_founding_users_roles!

  validates :plan, presence: { message: "must exist" }
  validates :users, length: { minimum: 1, message: "must have at least one admin user" }

  validates :name, presence: true
  validates :slug, presence: true, uniqueness: { case_sensitive: false }, format: { with: /\A[-a-z0-9]+\z/, message: "can only contain lowercase letters, numbers and dashes" }, length: { maximum: 255 }, exclusion: { in: Sluggable::EXCLUDED_SLUGS, message: "is reserved" }

  validate on: [:create, :update] do
    clean_slug = "#{slug}".tr "-", ""
    errors.add :slug, :not_allowed, message: "cannot resemble a UUID" if clean_slug =~ UUID_REGEX
  end

  scope :plan, -> (id) { where plan: id }

  after_commit :clear_cache!, on: [:update, :destroy]

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
    [:accounts, id].join ":"
  end

  def self.clear_cache!(id)
    key = Account.cache_key id

    Rails.cache.delete key
  end

  def clear_cache!
    Account.clear_cache! id
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

  def trialing_or_free_tier?
    return true if billing.nil?

    return (billing.trialing? && billing.card.nil?) ||
            plan.free?
  end

  def protected?
    protected
  end

  def admins
    users.admins
  end

  private

  def set_founding_users_roles!
    users.each { |u| u.grant! :admin }
  end

  def generate_secret_key!
    self.secret_key = SecureRandom.hex 64
  end
  alias_method :regenerate_secret_key!, :generate_secret_key!

  def generate_rsa_keys!
    priv = if rsa_private_key.nil?
             OpenSSL::PKey::RSA.generate RSA_KEY_SIZE
           else
             OpenSSL::PKey::RSA.new rsa_private_key
           end
    pub = priv.public_key

    self.rsa_private_key = priv.to_pem
    self.rsa_public_key = pub.to_pem
  end
  alias_method :regenerate_rsa_keys!, :generate_rsa_keys!

  def generate_dsa_keys!
    priv = if dsa_private_key.nil?
             OpenSSL::PKey::DSA.generate DSA_KEY_SIZE
           else
             OpenSSL::PKey::DSA.new dsa_private_key
           end
    pub = priv.public_key

    self.dsa_private_key = priv.to_pem
    self.dsa_public_key = pub.to_pem
  end
  alias_method :regenerate_dsa_keys!, :generate_dsa_keys!

  def generate_ecdsa_keys!
    priv = if ecdsa_private_key.nil?
             OpenSSL::PKey::EC.generate ECDSA_GROUP
           else
             OpenSSL::PKey::EC.new ecdsa_private_key
           end
    pub = priv.public_key

    self.ecdsa_private_key = priv.private_key.to_s(16).downcase
    self.ecdsa_public_key = pub.to_bn.to_s(16).downcase
  end
  alias_method :regenerate_ecdsa_keys!, :generate_ecdsa_keys!
end
