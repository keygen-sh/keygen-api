# frozen_string_literal: true

class Role < ApplicationRecord
  include Dirtyable

  USER_ROLES    = %w[user admin developer read_only sales_agent support_agent].freeze
  PRODUCT_ROLES = %w[product].freeze
  LICENSE_ROLES = %w[license].freeze
  ROLE_RANK     = {
    admin:         6,
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

  accepts_nested_attributes_for :role_permissions, reject_if: :reject_associated_records_for_role_permissions
  tracks_dirty_attributes_for :role_permissions

  # Set default permissions unless already set
  before_create -> { self.permissions = default_permission_ids },
    unless: :role_permissions_attributes_changed?

  # NOTE(ezekg) Sanity check
  validates :resource_type,
    inclusion: { in: [User.name, Product.name, License.name] }

  validates :name,
    inclusion: { in: USER_ROLES, message: 'must be a valid user role' },
    if: -> { resource.is_a?(User) }
  validates :name,
    inclusion: { in: PRODUCT_ROLES, message: 'must be a valid product role' },
    if: -> { resource.is_a?(Product) }
  validates :name,
    inclusion: { in: LICENSE_ROLES, message: 'must be a valid license role' },
    if: -> { resource.is_a?(License) }

  validates :permission_ids,
    inclusion: {
      in: -> role { role.allowed_permission_ids },
      message: 'unsupported permissions',
    }

  delegate :default_permissions, :default_permission_ids,
    :allowed_permissions, :allowed_permission_ids,
    allow_nil: true,
    to: :resource

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
  # permissions returns an array of the role's permissions.
  def permissions
    Permission.joins(:role_permissions)
              .where(
                role_permissions: { role_id: id },
              )
  end

  ##
  # permission_ids returns an array of the role's permission IDs,
  # including pending changes.
  def permission_ids
    if role_permissions_attributes_changed?
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
  # name= overloads role assignment so we can reset permissions
  # on role change.
  def name=(...)
    super(...)

    # Reset permissions on role change, using the intersection
    # of our current role's and the new role's defaults. This
    # ensures privilege escalation is unlikely. Only run when
    # role is persisted, i.e. on updates.
    self.permissions = permission_ids & default_permission_ids if
      persisted?
  end

  def rank
    ROLE_RANK.fetch(name) { -1 }
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

  def user?    = name.to_sym == :user
  def admin?   = name.to_sym == :admin
  def product? = name.to_sym == :product
  def license? = name.to_sym == :license

  def changed_for_autosave?
    super || role_permissions_attributes_changed?
  end

  def changed?
    super || role_permissions_attributes_changed?
  end

  private

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
