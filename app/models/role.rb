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
  has_many :role_permissions
  has_many :permissions,
    through: :role_permissions

  before_create :set_default_permissions!
  before_update :reset_permissions!,
    if: -> { resource.role.changed? }

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

  private

  def set_permissions!
    perms =
      case name.to_sym
      in :admin
        Permission.where(action: ADMIN_PERMISSIONS)
      in :developer
        Permission.where(action: ADMIN_PERMISSIONS)
      in :sales_agent
        Permission.where(action: ADMIN_PERMISSIONS)
      in :support_agent
        Permission.where(action: ADMIN_PERMISSIONS)
      in :read_only
        Permission.where(action: READ_ONLY_PERMISSIONS)
      in :product
        Permission.where(action: PRODUCT_PERMISSIONS)
      in :user
        Permission.where(action: USER_PERMISSIONS)
      in :license
        Permission.where(action: LICENSE_PERMISSIONS)
      end

    RolePermission.upsert_all(
      perms.ids.map {{ permission_id: _1, role_id: id }},
      on_duplicate: :skip,
    )
  end

  def set_default_permissions!
    self.id ||= SecureRandom.uuid

    set_permissions!
  end

  def reset_permissions!
    self.permissions = []

    set_permissions!
  end
end
