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
  before_create :generate_keys!

  after_create :set_founding_users_roles

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

  def set_founding_users_roles
    users.each { |u| u.grant :admin }
  end

  def generate_keys!
    priv = if private_key.nil?
             OpenSSL::PKey::RSA.generate RSA_KEY_SIZE
           else
             OpenSSL::PKey::RSA.new private_key
           end
    pub = priv.public_key

    self.private_key = priv.to_pem
    self.public_key = pub.to_pem
  end
  alias_method :regenerate_keys!, :generate_keys!
end
