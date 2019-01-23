class Token < ApplicationRecord
  TOKEN_DURATION = 2.weeks

  include Tokenable
  include Limitable
  include Pageable

  belongs_to :account
  belongs_to :bearer, polymorphic: true

  attr_reader :raw

  validates :account, presence: true
  validates :bearer, presence: true

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

  scope :bearer, -> (id) { where bearer: id }

  # FIXME(ezekg) This is not going to clear a v1 token's cache since we don't
  #              store the raw token value.
  after_commit :clear_cache!, on: [:update, :destroy]

  def self.cache_key(token)
    hash = Digest::SHA256.hexdigest token

    [:tokens, hash].join ":"
  end

  def self.clear_cache!(token)
    key = Token.cache_key token

    Rails.cache.delete key
  end

  def clear_cache!
    Token.clear_cache! digest
  end

  def generate!(version: Tokenable::ALGO_VERSION)
    @raw, enc = generate_hashed_token :digest, version: version do |token|
      case version
      when "v1"
        "#{account.id.delete "-"}.#{id.delete "-"}.#{token}"
      when "v2"
        "#{kind[0..3]}-#{token}"
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

  def product_token?
    bearer.role? :product
  end

  def admin_token?
    bearer.role? :admin
  end

  def user_token?
    bearer.role? :user
  end

  def activation_token?
    bearer.role? :license
  end

  def kind
    case
    when product_token?
      "product-token"
    when admin_token?
      "admin-token"
    when user_token?
      "user-token"
    when activation_token?
      "activation-token"
    end
  end
end
