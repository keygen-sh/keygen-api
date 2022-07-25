# frozen_string_literal: true

class Role < ApplicationRecord
  include Permissible

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
    reject_if: :reject_duplicate_role_permissions

  # We're doing this in an after create commit so we can use a bulk insert,
  # which is more performant than inserting tens of permissions.
  after_create :set_default_permissions!,
    unless: :role_permissions_attributes_changed?

  before_update :reset_permissions!,
    if: :name_changed?

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

  def role_permissions_attributes_changed? = !@role_permissions_attributes_before_type_cast.nil?
  def role_permissions_attributes=(attributes)
    @role_permissions_attributes_before_type_cast ||= attributes.dup

    self._role_permissions_attributes = attributes
  end

  # Instead of doing a has_many(through:), we're doing this so that we can
  # allow permissions to be attached by action via the resource, rather than
  # by ID. We don't expose permission IDs to the world. This also allows
  # us to insert in bulk, rather than serially.
  def permissions=(*ids)
    permission_attrs = ids.flatten.map {{ permission_id: _1 }}

    return assign_attributes(role_permissions_attributes: permission_attrs) if
      new_record?

    transaction do
      role_permissions.delete_all

      return if
        permission_attrs.empty?

      role_permissions.insert_all!(permission_attrs)
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

  private

  def reject_duplicate_role_permissions(attrs)
    return if
      new_record?

    role_permissions.exists?(attrs)
  end

  def set_default_permissions!
    actions = case name.to_sym
              in :admin
                Permission::ADMIN_PERMISSIONS
              in :developer
                Permission::ADMIN_PERMISSIONS
              in :sales_agent
                Permission::ADMIN_PERMISSIONS
              in :support_agent
                Permission::ADMIN_PERMISSIONS
              in :read_only
                Permission::READ_ONLY_PERMISSIONS
              in :product
                Permission::PRODUCT_PERMISSIONS
              in :user
                Permission::USER_PERMISSIONS
              in :license
                Permission::LICENSE_PERMISSIONS
              end

    role_permissions.insert_all!(
      Permission.where(action: actions)
                .pluck(:id)
                .map {{ permission_id: _1 }},
    )
  end

  def reset_permissions!
    transaction do
      role_permissions.delete_all

      set_default_permissions!
    end
  end
end
