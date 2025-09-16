# frozen_string_literal: true

class Token < ApplicationRecord
  include Keygen::EE::ProtectedMethods[:permissions=, entitlements: %i[permissions]]

  TOKEN_DURATION = 2.weeks

  include Environmental
  include Accountable
  include Tokenable
  include Limitable
  include Orderable
  include Pageable
  include Permissible
  include Dirtyable

  belongs_to :bearer,
    polymorphic: true

  # FIXME(ezekg) sessions must come before permissions otherwise autosave breaks
  has_many :sessions,
    dependent: :delete_all,
    autosave: true

  has_many :token_permissions,
    dependent: :delete_all,
    autosave: true

  has_many :permissions, through: :token_permissions do
    def actions = loaded? ? collect(&:action) : super
  end

  has_environment default: -> {
    case bearer
    in Environment(id: environment_id)
      environment_id
    in environment_id:
      environment_id
    else
      nil
    end
  }
  has_account default: -> { bearer&.account_id }
  has_permissions Permission::ALL_PERMISSIONS,
    # Default to wildcard permission but allow all
    default: %w[*]

  accepts_nested_attributes_for :token_permissions, reject_if: :reject_associated_records_for_token_permissions
  tracks_nested_attributes_for :token_permissions

  tracks_attributes :expiry

  # Set default permissions unless already set
  before_validation :set_default_permissions,
    unless: :token_permissions_attributes_assigned?,
    on: :create

  # Set default expiry unless already set
  before_create :set_default_expiry,
    unless: :expiry_attribute_assigned?

  # Generate the actual token
  after_create :generate!

  attr_reader :raw

  validates :bearer,
    presence: { message: 'must exist' },
    scope: { by: :account_id }

  validates :permission_ids,
    if: :bearer_id?,
    inclusion: {
      message: 'unsupported permissions',
      in: -> token {
        permission_ids = token.bearer.permission_ids
        wildcard_id    = Permission.wildcard_id

        return token.bearer.allowed_permission_ids if
          permission_ids.include?(wildcard_id)

        permission_ids << wildcard_id
      },
    }

  validates :max_activations, numericality: { greater_than_or_equal_to: 0 }, allow_nil: true, allow_blank: true, if: :activation_token?
  validates :max_deactivations, numericality: { greater_than_or_equal_to: 0 }, allow_nil: true, allow_blank: true, if: :activation_token?
  validates :activations, numericality: { greater_than_or_equal_to: 0 }, if: :activation_token?
  validates :deactivations, numericality: { greater_than_or_equal_to: 0 }, if: :activation_token?

  validates :name,
    length: { maximum: 255 }

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

  scope :accessible_by, -> accessor {
    case accessor
    in role: Role(:admin)
      all
    in role: Role(:environment)
      for_environment(accessor)
        .where.not(
          bearer: accessor.admins.reorder(nil),
        )
        .or(
          where(bearer: accessor),
        )
    in role: Role(:product)
      for_product(accessor.id)
        .or(
          where(bearer: accessor.licenses.reorder(nil)),
        )
        .or(
          where(bearer: accessor.users.reorder(nil)),
        )
    in role: Role(:user)
      for_user(accessor.id)
    in role: Role(:license)
      for_license(accessor.id)
    else
      none
    end
  }

  scope :for_product, -> id { for_bearer(Product.name, id) }
  scope :for_license, -> id { for_bearer(License.name, id) }
  scope :for_user,    -> id { for_bearer(User.name, id) }

  scope :for_bearer, -> *terms {
    case terms
    in [ActiveRecord::Base => bearer]
      where(bearer:)
    in [Hash => params]
      for_bearer(params.symbolize_keys.values_at(:type, :id))
    in [[String | Symbol => type, String => id]]
      for_bearer_type(type).for_bearer_id(id)
    in [String | Symbol => type, String => id]
      for_bearer_type(type).for_bearer_id(id)
    in [String => id]
      for_bearer_id(id)
    else
      none
    end
  } do
    def environments = for_bearer_type(:environment)
    def products     = for_bearer_type(:product)
    def licenses     = for_bearer_type(:license)
    def users        = for_bearer_type(:user)
  end

  scope :for_bearer_type, -> type {
    bearer_type = type.to_s.underscore.classify
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

  delegate :role, :role_permissions,
    allow_nil: true,
    to: :bearer

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

      raise ActiveRecord::RecordInvalid, self
    end

    assign_attributes(
      token_permissions_attributes: permission_ids.map {{ permission_id: _1 }},
    )
  end

  # override permissions reader to intersect with bearer's permissions
  def permissions
    return pending_permissions if
      token_permissions_attributes_assigned?

    perms = super

    # When the token has a wildcard permission, defer to bearer.
    return bearer.permissions if
      perms.include?(Permission.wildcard)

    # When the bearer has a wildcard permission, defer to token.
    return perms if
      bearer.permissions.include?(Permission.wildcard)

    # A token's permission set is the intersection of its bearer's
    # permissions and its own token permissions.
    Permission.wrap(bearer.permissions & perms)
  end

  def pending_permissions
    return Permission.none unless
      token_permissions_attributes_assigned?

    Permission.where(
      id: token_permissions_attributes.collect { _1[:permission_id] },
    )
  end

  def permission_ids
    if token_permissions_attributes_assigned?
      token_permissions_attributes.collect { _1[:permission_id] }
    else
      token_permissions.collect(&:permission_id)
    end
  end

  def reset_permissions!
    update!(permissions: default_permission_ids)
  end

  def generate!(version: Tokenable::ALGO_VERSION)
    length =
      case
      when activation_token?
        16
      else
        32
      end

    # store ephemeral raw value and persist digest value
    @raw, digest = generate_hashed_token :digest, length: length, version: version do |token|
      case version
      when "v1"
        "#{account.id.delete "-"}.#{id.delete "-"}.#{token}"
      when "v2"
        "#{kind[0..3]}-#{token}"
      when "v3"
        "#{prefix}-#{token}"
      end
    end

    self.digest = digest

    save!
  end

  def regenerate!(session: nil, **)
    self.expiry = Time.current + TOKEN_DURATION if expiry.present?

    transaction do
      sessions.delete_all # expire all of the token's sessions

      # rebuild the session if its token matches the regenerated token
      sesh = if session.present? && session.token == self
               sessions.build(
                 expiry: session.expiry, # don't implicitly extend session
                 user_agent: session.user_agent,
                 ip: session.ip,
               )
             end

      generate!(**)

      sesh
    end
  end

  def expired?
    return false if expiry.nil?

    expiry < Time.current
  end

  def orphaned_token?
    bearer.nil?
  end

  def environment_token?
    return false if orphaned_token?

    bearer.has_role? :environment
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
    when environment_token?
      "environment-token"
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
    when environment_token?
      :env
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

  def changed_for_autosave?
    super || token_permissions_attributes_assigned?
  end

  def changed?
    super || token_permissions_attributes_assigned?
  end

  private

  def set_default_permissions
    assign_attributes(
      token_permissions_attributes: default_permission_ids.map {{ permission_id: _1 }},
    )
  end

  def set_default_expiry
    # NOTE(ezekg) Non-user tokens do not expire by default (admin, env, product, license, etc.)
    self.expiry = if bearer in role: Role(:user)
                    Time.current + TOKEN_DURATION
                  else
                    nil
                  end
  end

  ##
  # reject_associated_records_for_token_permissions rejects duplicate token permissions.
  def reject_associated_records_for_token_permissions(attrs)
    return if
      new_record?

    token_permissions.exists?(
      # Make sure we only select real columns, not e.g. _destroy.
      attrs.slice(attributes.keys),
    )
  end

  ##
  # autosave_associated_records_for_token_permissions bulk inserts token permissions instead
  # of saving them sequentially, which is incredibly slow with 100+ permissions.
  def autosave_associated_records_for_token_permissions
    return unless
      token_permissions_attributes.present?

    transaction do
      token_permissions.delete_all

      # FIXME(ezekg) Can't use token_permissions.upsert_all at this point, because for
      #              some reason token_id ends up being nil. Instead, we'll use the
      #              class method and then call reload.
      TokenPermission.upsert_all(
        token_permissions_attributes.map { _1.merge(token_id: id) },
        record_timestamps: true,
        on_duplicate: :skip,
      )

      reload
    end
  end
end
