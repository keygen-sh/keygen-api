# frozen_string_literal: true

class Role < ApplicationRecord
  include Keygen::EE::ProtectedMethods[:permissions=, entitlements: %i[permissions]]
  include Keygen::PortableClass
  include Dirtyable

  USER_ROLES        = %w[user admin developer read_only sales_agent support_agent].freeze
  ENVIRONMENT_ROLES = %w[environment].freeze
  PRODUCT_ROLES     = %w[product].freeze
  LICENSE_ROLES     = %w[license].freeze
  ROLE_RANK         = {
    admin:         7,
    environment:   6,
    developer:     5,
    product:       4,
    sales_agent:   3,
    support_agent: 2,
    read_only:     1,
    license:       0,
    user:          0,
  }.with_indifferent_access
   .freeze

  belongs_to :resource,
    polymorphic: true,
    inverse_of: :role
  has_many :role_permissions,
    dependent: :delete_all,
    inverse_of: :role,
    autosave: true

  has_many :permissions, through: :role_permissions do
    def actions = loaded? ? collect(&:action) : super
  end

  # FIXME(ezekg) should have an account_id foreign key
  delegate :account, :account_id,
    :default_permissions, :default_permission_ids,
    :allowed_permissions, :allowed_permission_ids,
    allow_nil: true,
    to: :resource

  accepts_nested_attributes_for :role_permissions, reject_if: :reject_associated_records_for_role_permissions
  tracks_nested_attributes_for :role_permissions

  # Set default permissions unless already set
  before_create :set_default_permissions,
    unless: :role_permissions_attributes_assigned?

  # NOTE(ezekg) Sanity checks
  validates :resource_type,
    inclusion: { in: [User.name, Environment.name, Product.name, License.name] }

  validates :name,
    inclusion: { in: USER_ROLES, message: 'must be a valid user role' },
    if: -> {
      resource.is_a?(User)
    }

  validates :name,
    inclusion: { in: ENVIRONMENT_ROLES, message: 'must be a valid environment role' },
    if: -> {
      resource.is_a?(Environment)
    }

  validates :name,
    inclusion: { in: PRODUCT_ROLES, message: 'must be a valid product role' },
    if: -> {
      resource.is_a?(Product)
    }

  validates :name,
    inclusion: { in: LICENSE_ROLES, message: 'must be a valid license role' },
    if: -> {
      resource.is_a?(License)
    }

  validates :permission_ids,
    inclusion: {
      in: -> role { role.allowed_permission_ids },
      message: 'unsupported permissions',
    }

  ##
  # permissions= sets the role's permissions. It does not save automatically.
  #
  # Instead of doing a has_many(through:), we're doing this so that we can
  # allow permissions to be attached by action via the resource, rather than
  # by ID. We don't expose permission IDs to the world. This also allows
  # us to insert in bulk, rather than serially.
  def permissions=(*ids)
    return if
      ids == [nil]

    assign_attributes(
      role_permissions_attributes: ids.flatten
                                      .compact
                                      .map {{ permission_id: _1 }},
    )
  end

  ##
  # permissions overrides association reader to include pending permission changes
  def permissions
    return pending_permissions if
      role_permissions_attributes_assigned?

    super
  end

  ##
  # pending_permissions permissions returns the role's pending permissions,
  # via the :role_permissions nested attributes.
  def pending_permissions
    return Permission.none unless
      role_permissions_attributes_assigned?

    Permission.where(
      id: role_permissions_attributes.collect { _1[:permission_id] },
    )
  end

  ##
  # permission_ids returns an array of the role's permission IDs,
  # including pending changes.
  def permission_ids
    if role_permissions_attributes_assigned?
      role_permissions_attributes.collect { _1[:permission_id] }
    else
      role_permissions.collect(&:permission_id)
    end
  end

  ##
  # reset_permissions! resets the role's permissions to defaults.
  def reset_permissions!
    update!(permissions: default_permission_ids)
  end

  ##
  # reset_permissions resets the role's permission attributes to defaults.
  def reset_permissions
    self.permissions = default_permission_ids
  end

  ##
  # name= overloads role assignment so we can reset permissions
  # on role change.
  def name=(...)
    super(...)

    # Reset permissions on role change by using the intersection of our
    # current role's permissions and the new role's default permisisons.
    # This helps prevent prevents accidental privilege escalation, e.g.
    # for user => admin => user.
    #
    # Only run when role is persisted, i.e. on updates.
    return unless
      persisted?

    self.permissions = permission_ids & (default_permission_ids << Permission.wildcard_id)
  end

  ##
  # deconstruct allows pattern pattern matching like:
  #
  #   role in Role(:admin | :user)
  #
  def deconstruct = [name.to_sym]

  def rank
    ROLE_RANK.fetch(name) { -1 }
  end

  def ===(comparison_role)
    comparison_role.equal?(self) ||
      comparison_role.instance_of?(self.class) &&
        comparison_role.id == id
  end

  def ==(comparison_role)
    rank == comparison_role.rank &&
      name == comparison_role.name
  end

  def <=(comparison_role)
    rank <= comparison_role.rank
  end

  def <(comparison_role)
    rank < comparison_role.rank
  end

  def >=(comparison_role)
    rank >= comparison_role.rank
  end

  def >(comparison_role)
    rank > comparison_role.rank
  end

  def user?        = name.to_sym == :user
  def admin?       = name.to_sym == :admin
  def environment? = name.to_sym == :environment
  def product?     = name.to_sym == :product
  def license?     = name.to_sym == :license

  def changed_for_autosave?
    super || role_permissions_attributes_assigned?
  end

  def changed?
    super || role_permissions_attributes_assigned?
  end

  private

  def set_default_permissions
    assign_attributes(
      role_permissions_attributes: default_permission_ids.map {{ permission_id: _1 }},
    )
  end

  ##
  # reject_associated_records_for_role_permissions rejects duplicate role permissions.
  def reject_associated_records_for_role_permissions(attrs)
    return if
      new_record?

    role_permissions.exists?(
      # Make sure we only select real columns, not e.g. _destroy.
      attrs.slice(attributes.keys),
    )
  end

  ##
  # autosave_associated_records_for_role_permissions bulk inserts role permissions instead
  # of saving them sequentially, which is incredibly slow with 100+ permissions.
  def autosave_associated_records_for_role_permissions
    return if
      role_permissions_attributes.nil?

    transaction do
      role_permissions.delete_all

      if role_permissions_attributes.any?
        # FIXME(ezekg) Can't use role_permissions.upsert_all at this point, because for
        #              some reason role_id ends up being nil. Instead, we'll use the
        #              class method and then call reload.
        RolePermission.upsert_all(
          role_permissions_attributes.map { _1.merge(role_id: id) },
          record_timestamps: true,
          on_duplicate: :skip,
        )
      end

      reload
    end
  end
end
