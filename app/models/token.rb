# frozen_string_literal: true

class Token < ApplicationRecord
  TOKEN_DURATION = 2.weeks

  include Tokenable
  include Limitable
  include Orderable
  include Pageable
  include Permissible

  belongs_to :account
  belongs_to :bearer, polymorphic: true
  has_many :token_permissions
  has_many :permissions,
    through: :token_permissions

  before_create :set_permissions!,
    if: -> { permissions.empty? }

  # FIXME(ezekg) This is not going to clear a v1 token's cache since we don't
  #              store the raw token value.
  after_commit :clear_cache!,
    on: %i[update destroy]

  attr_reader :raw

  validates :account, presence: true
  validates :bearer,
    scope: { by: :account_id },
    presence: true

  validates :max_activations, numericality: { greater_than_or_equal_to: 0 }, allow_nil: true, allow_blank: true, if: :activation_token?
  validates :max_deactivations, numericality: { greater_than_or_equal_to: 0 }, allow_nil: true, allow_blank: true, if: :activation_token?
  validates :activations, numericality: { greater_than_or_equal_to: 0 }, if: :activation_token?
  validates :deactivations, numericality: { greater_than_or_equal_to: 0 }, if: :activation_token?

  validate on: :update, if: :activation_token? do |token|
    next if token&.activations.nil? || token.max_activations.nil?
    next if token.activations <= token.max_activations

    token.errors.add :activations, :limit_exceeded, message: "exceeds maximum allowed (#{token.max_activations})"
  end

  validate on: :update, if: :activation_token? do |token|
    next if token&.deactivations.nil? || token.max_deactivations.nil?
    next if token.deactivations <= token.max_deactivations

    token.errors.add :deactivations, :limit_exceeded, message: "exceeds maximum allowed (#{token.max_deactivations})"
  end

  scope :for_bearer, -> type, id {
    for_bearer_type(type).for_bearer_id(id)
  }

  scope :for_bearer_type, -> type {
    bearer_type = type.to_s.underscore.singularize.classify
    return none if
      bearer_type.empty?

    where(bearer_type: bearer_type)
  }

  scope :for_bearer_id, -> id {
    bearer_id = id.to_s
    return none if
      bearer_id.empty?

    where(bearer_id: bearer_id)
  }

  def self.cache_key(digest)
    hash = Digest::SHA256.hexdigest digest

    [:tokens, hash, CACHE_KEY_VERSION].join ":"
  end

  def cache_key
    return if digest.nil?

    Token.cache_key digest
  end

  def self.clear_cache!(digest)
    key = Token.cache_key digest

    Rails.cache.delete key
  end

  def clear_cache!
    return if digest.nil?

    Token.clear_cache! digest
  end

  def generate!(version: Tokenable::ALGO_VERSION)
    length =
      case
      when activation_token?
        16
      else
        32
      end

    @raw, enc = generate_hashed_token :digest, length: length, version: version do |token|
      case version
      when "v1"
        "#{account.id.delete "-"}.#{id.delete "-"}.#{token}"
      when "v2"
        "#{kind[0..3]}-#{token}"
      when "v3"
        "#{prefix}-#{token}"
      end
    end

    self.digest = enc
    save

    raw
  end

  def regenerate!(**kwargs)
    self.expiry = Time.current + TOKEN_DURATION if expiry.present?

    generate! **kwargs
  end

  def expired?
    return false if expiry.nil?

    expiry < Time.current
  end

  def orphaned_token?
    bearer.nil?
  end

  def product_token?
    return false if orphaned_token?

    bearer.has_role? :product
  end

  def admin_token?
    return false if orphaned_token?

    bearer.has_role? :admin
  end

  def developer_token?
    return false if orphaned_token?

    bearer.has_role? :developer
  end

  def sales_token?
    return false if orphaned_token?

    bearer.has_role? :sales_agent
  end

  def support_token?
    return false if orphaned_token?

    bearer.has_role? :support_agent
  end

  def read_only_token?
    return false if orphaned_token?

    bearer.has_role?(:read_only)
  end

  def user_token?
    return false if orphaned_token?

    bearer.has_role? :user
  end

  def activation_token?
    return false if orphaned_token?

    bearer.has_role? :license
  end

  def kind
    case
    when orphaned_token?
      "orphaned-token"
    when product_token?
      "product-token"
    when admin_token?
      "admin-token"
    when user_token?
      "user-token"
    when activation_token?
      "activation-token"
    when developer_token?
      "developer-token"
    when sales_token?
      "sales-token"
    when support_token?
      "support-token"
    when read_only_token?
      "read-only-token"
    else
      "token"
    end
  end

  def prefix
    case
    when product_token?
      :prod
    when admin_token?
      :admin
    when user_token?
      :user
    when activation_token?
      :activ
    when developer_token?
      :dev
    when sales_token?
      :sales
    when support_token?
      :spprt
    when read_only_token?
      :read
    else
      :token
    end
  end

  private

  def set_permissions!
    self.id = SecureRandom.uuid

    TokenPermission.insert_all!(
      bearer.permission_ids.map { { permission_id: _1, token_id: id } },
    )
  end
end
