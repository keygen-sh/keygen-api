# frozen_string_literal: true

class Role < ApplicationRecord
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
    polymorphic: true
  has_many :role_permissions,
    dependent: :delete_all

  accepts_nested_attributes_for :role_permissions,
    reject_if: :reject_associated_records_for_role_permissions

  # We're doing this in an after create commit so we can use a bulk insert,
  # which is more performant than inserting tens of permissions.
  after_create :set_default_permissions!,
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

  # FIXME(ezekg) Can't find a way to determine whether or not nested attributes
  #              have been provided. This adds a flag we can check. Will be nil
  #              when nested attributes have not been provided.
  alias :_role_permissions_attributes= :role_permissions_attributes=

  def role_permissions_attributes_changed? = instance_variable_defined?(:@role_permissions_attributes_before_type_cast)
  def role_permissions_attributes=(attributes)
    @role_permissions_attributes_before_type_cast = attributes.dup

    self._role_permissions_attributes = attributes
  end

  # Instead of doing a has_many(through:), we're doing this so that we can
  # allow permissions to be attached by action via the resource, rather than
  # by ID. We don't expose permission IDs to the world. This also allows
  # us to insert in bulk, rather than serially.
  def permissions=(*ids)
    return if
      ids == [nil]

    role_permissions_attributes = ids.flatten
                                     .compact
                                     .map {{ permission_id: _1 }}

    return assign_attributes(role_permissions_attributes:) unless
      persisted?

    transaction do
      role_permissions.delete_all

      return if
        role_permissions_attributes.empty?

      role_permissions.insert_all!(role_permissions_attributes)
    end
  end

  def permissions
    Permission.joins(:role_permissions)
              .where(
                role_permissions: { role_id: id },
              )
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

  def deconstruct_keys(keys) = attributes.symbolize_keys.except(keys)
  def deconstruct            = attributes.values

  private

  ##
  # reject_associated_records_for_role_permissions rejects duplicate role permissions.
  def reject_associated_records_for_role_permissions(attrs)
    return if
      new_record?

    role_permissions.exists?(attrs)
  end

  ##
  # autosave_associated_records_for_role_permissions bulk inserts role permissions instead
  # of saving them sequentially, which is incredibly slow.
  def autosave_associated_records_for_role_permissions
    return if
      role_permissions.empty?

    to_delete = role_permissions.select(&:marked_for_destruction?)
                                .map(&:id)

    to_upsert = role_permissions.reject(&:marked_for_destruction?)
                                .map {{
                                  permission_id: _1.permission_id,
                                  role_id: id,
                                }}

    transaction do
      RolePermission.where(id: to_delete).delete_all if
        to_delete.any?

      RolePermission.upsert_all(to_upsert, on_duplicate: :skip) if
        to_upsert.any?
    end
  end
end
