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

  DEFAULT_ADMIN_PERMISSIONS = %w[
    account.billing.read
    account.billing.update
    account.plan.read
    account.plan.update
    account.read
    account.subscription.read
    account.subscription.cancel
    account.subscription.pause
    account.subscription.renew
    account.subscription.resume
    account.update

    arch.read

    artifact.create
    artifact.delete
    artifact.download
    artifact.read
    artifact.update
    artifact.upload

    channel.read

    entitlement.create
    entitlement.delete
    entitlement.read
    entitlement.update

    event-log.read

    group.create
    group.delete
    group.read
    group.update
    group.owner.attach
    group.owner.detach
    group.owner.read

    key.create
    key.delete
    key.read
    key.update

    license.check-in
    license.check-out
    license.create
    license.delete
    license.entitlements.attach
    license.entitlements.detach
    license.entitlements.read
    license.group.update
    license.permissions.attach
    license.permissions.detach
    license.permissions.read
    license.policy.update
    license.read
    license.reinstate
    license.renew
    license.revoke
    license.suspend
    license.tokens.generate
    license.tokens.read
    license.update
    license.usage.decrement
    license.usage.increment
    license.usage.reset
    license.user.update
    license.validate

    machine.check-out
    machine.create
    machine.delete
    machine.group.update
    machine.heartbeat.ping
    machine.heartbeat.reset
    machine.proofs.generate
    machine.update
    machine.read

    policy.create
    policy.delete
    policy.entitlements.attach
    policy.entitlements.detach
    policy.entitlements.read
    policy.permissions.attach
    policy.permissions.detach
    policy.permissions.read
    policy.pool.pop
    policy.read
    policy.update

    process.create
    process.delete
    process.heartbeat.ping
    process.read

    product.create
    product.delete
    product.read
    product.permissions.attach
    product.permissions.detach
    product.tokens.generate
    product.tokens.read
    product.update

    platform.read

    release.constraints.attach
    release.constraints.detach
    release.constraints.read
    release.create
    release.delete
    release.download
    release.publish
    release.read
    release.update
    release.upgrade
    release.upload
    release.yank

    request-log.read

    second-factor.create
    second-factor.delete
    second-factor.disable
    second-factor.enable
    second-factor.read

    token.generate
    token.regenerate
    token.read
    token.revoke

    user.ban
    user.create
    user.delete
    user.group.update
    user.password.reset
    user.permissions.attach
    user.permissions.detach
    user.permissions.read
    user.read
    user.tokens.generate
    user.tokens.read
    user.unban
    user.update

    webhook-endpoint.create
    webhook-endpoint.delete
    webhook-endpoint.read
    webhook-endpoint.update

    webhook-event.delete
    webhook-event.read
    webhook-event.retry
  ].freeze

  DEFAULT_READ_ONLY_PERMISSIONS = %w[
    account.billing.read
    account.plan.read
    account.read
    account.subscription.read
    arch.read
    artifact.read
    channel.read
    entitlement.read
    event-log.read
    group.read
    group.owner.read
    key.read
    license.entitlements.read
    license.permissions.read
    license.read
    license.tokens.read
    machine.read
    policy.entitlements.read
    policy.permissions.read
    policy.read
    process.read
    product.read
    product.tokens.read
    platform.read
    release.constraints.read
    release.read
    request-log.read
    second-factor.read
    token.read
    user.permissions.read
    user.read
    webhook-endpoint.read
    webhook-event.read
  ].freeze

  DEFAULT_PRODUCT_PERMISSIONS = %w[
    account.read

    arch.read

    artifact.create
    artifact.delete
    artifact.download
    artifact.read
    artifact.update
    artifact.upload

    channel.read

    entitlement.read

    group.create
    group.delete
    group.read
    group.update
    group.owner.attach
    group.owner.detach
    group.owner.read

    key.create
    key.delete
    key.read
    key.update

    license.check-in
    license.check-out
    license.create
    license.delete
    license.entitlements.attach
    license.entitlements.detach
    license.entitlements.read
    license.group.update
    license.permissions.attach
    license.permissions.detach
    license.permissions.read
    license.policy.update
    license.read
    license.reinstate
    license.renew
    license.revoke
    license.suspend
    license.tokens.generate
    license.tokens.read
    license.update
    license.usage.decrement
    license.usage.increment
    license.usage.reset
    license.user.update
    license.validate

    machine.check-out
    machine.create
    machine.delete
    machine.group.update
    machine.heartbeat.ping
    machine.heartbeat.reset
    machine.proofs.generate
    machine.update
    machine.read

    policy.create
    policy.delete
    policy.entitlements.attach
    policy.entitlements.detach
    policy.entitlements.read
    policy.pool.pop
    policy.read
    policy.update

    process.create
    process.delete
    process.heartbeat.ping
    process.read

    product.read
    product.update
    product.tokens.read

    platform.read

    release.constraints.attach
    release.constraints.detach
    release.constraints.read
    release.create
    release.delete
    release.download
    release.publish
    release.read
    release.update
    release.upgrade
    release.upload
    release.yank

    token.generate
    token.regenerate
    token.revoke
    token.read

    user.ban
    user.create
    user.delete
    user.group.update
    user.password.reset
    user.permissions.read
    user.read
    user.unban
    user.update

    webhook-event.read
  ].freeze

  DEFAULT_USER_PERMISSIONS = %w[
    account.read

    arch.read

    artifact.download
    artifact.read

    channel.read

    group.read
    group.owner.read

    license.check-in
    license.check-out
    license.create
    license.entitlements.read
    license.delete
    license.policy.update
    license.read
    license.renew
    license.revoke
    license.usage.increment
    license.validate

    machine.check-out
    machine.create
    machine.delete
    machine.heartbeat.ping
    machine.proofs.generate
    machine.read
    machine.update

    policy.read

    process.create
    process.delete
    process.heartbeat.ping
    process.read

    product.read

    platform.read

    release.constraints.read
    release.download
    release.read
    release.upgrade

    token.generate
    token.regenerate
    token.revoke
    token.read

    user.password.reset
    user.read
    user.update
    user.tokens.read
  ].freeze

  DEFAULT_LICENSE_PERMISSIONS = %w[
    account.read

    arch.read

    artifact.download
    artifact.read

    channel.read

    group.read

    license.check-in
    license.check-out
    license.entitlements.read
    license.read
    license.usage.increment
    license.validate

    machine.check-out
    machine.create
    machine.delete
    machine.heartbeat.ping
    machine.proofs.generate
    machine.read
    machine.update

    policy.read

    process.create
    process.delete
    process.heartbeat.ping
    process.read

    product.read

    platform.read

    release.constraints.read
    release.download
    release.read
    release.upgrade

    user.read
  ].freeze

  belongs_to :resource,
    polymorphic: true
  has_many :role_permissions
  has_many :permissions,
    through: :role_permissions

  before_create :set_permissions!
  before_update :reset_permissions!

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
    self.id = SecureRandom.uuid

    perms =
      case name.to_sym
      in :admin
        Permission.where(action: DEFAULT_ADMIN_PERMISSIONS)
      in :developer
        Permission.where(action: DEFAULT_ADMIN_PERMISSIONS)
      in :sales_agent
        Permission.where(action: DEFAULT_ADMIN_PERMISSIONS)
      in :support_agent
        Permission.where(action: DEFAULT_ADMIN_PERMISSIONS)
      in :read_only
        Permission.where(action: DEFAULT_READ_ONLY_PERMISSIONS)
      in :product
        Permission.where(action: DEFAULT_PRODUCT_PERMISSIONS)
      in :user
        Permission.where(action: DEFAULT_USER_PERMISSIONS)
      in :license
        Permission.where(action: DEFAULT_LICENSE_PERMISSIONS)
      end

    RolePermission.insert_all!(
      perms.ids.map { { permission_id: _1, role_id: id } },
    )
  end

  def reset_permissions!
    self.permissions = []

    set_permissions!
  end
end
