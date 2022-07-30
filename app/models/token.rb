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
  has_many :token_permissions,
    dependent: :delete_all

  accepts_nested_attributes_for :token_permissions,
    reject_if: :reject_associated_records_for_token_permissions

  before_create :set_default_permissions!,
    unless: :token_permissions_attributes_changed?

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

  delegate :role,
    allow_nil: true,
    to: :bearer

  # FIXME(ezekg) Can't find a way to determine whether or not nested attributes
  #              have been provided. This adds a flag we can check. Will be nil
  #              when nested attributes have not been provided.
  alias :_token_permissions_attributes= :token_permissions_attributes=

  def token_permissions_attributes_changed? = instance_variable_defined?(:@token_permissions_attributes_before_type_cast)
  def token_permissions_attributes=(attributes)
    @token_permissions_attributes_before_type_cast = attributes.dup

    self._token_permissions_attributes = attributes
  end

  # Instead of doing a has_many(through:), we're doing this so that we can
  # allow permissions to be attached by action, rather than just ID. This
  # also allows us to insert in bulk, rather than serially.
  def permissions=(*identifiers)
    return if
      identifiers == [nil]

    identifiers = identifiers.flatten
                             .compact

    permission_ids =
      Permission.where(action: identifiers)
                .or(
                  Permission.where(id: identifiers)
                )
                .pluck(:id)

    # Invalid permissions would be ignored by default, but that doesn't
    # really provide a nice DX. We'll error instead of ignoring.
    if permission_ids.size != identifiers.size
      errors.add :permissions, :not_allowed, message: 'unsupported permissions'

      return
    end

    token_permissions_attributes =
      permission_ids.map {{ permission_id: _1 }}

    return assign_attributes(token_permissions_attributes:) unless
      persisted?

    transaction do
      token_permissions.delete_all

      return if
        permission_ids.empty?

      token_permissions.insert_all!(token_permissions_attributes)
    end
  end

  def permissions
    return [] unless
      role.present?

    return role.permissions if
      token_permissions.joins(:permission)
                       .exists?(permission: {
                         action: Permission::WILDCARD_PERMISSION,
                       })

    # A token's permission set is the intersection of its bearer's role
    # permissions and its own token permissions.
    Permission.distinct
              .joins(:role_permissions, :token_permissions)
              .where(
                role_permissions: { role_id: role.id },
                token_permissions: { token_id: id },
              )
              .reorder(nil)
  end

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
    save!

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

  def reject_associated_records_for_token_permissions(attrs)
    return if
      new_record?

    token_permissions.exists?(attrs)
  end

  def set_default_permissions!
    permission_id = Permission.where(action: Permission::WILDCARD_PERMISSION)
                              .pick(:id)

    # By default, a token inherits its role's permissions using a wildcard.
    assign_attributes(token_permissions_attributes: [{ permission_id: }])
  end
end
