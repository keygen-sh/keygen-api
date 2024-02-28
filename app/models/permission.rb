# frozen_string_literal: true

class Permission < ApplicationRecord
  has_many :role_permissions
  has_many :token_permissions
  has_many :group_permissions

  # The action name of the wildcard permission.
  WILDCARD_PERMISSION = '*'.freeze

  # Available permissions.
  ALL_PERMISSIONS = %w[
    account.analytics.read
    account.billing.read
    account.billing.update
    account.plan.read
    account.plan.update
    account.read
    account.subscription.read
    account.subscription.update
    account.update

    admin.create
    admin.delete
    admin.invite
    admin.read
    admin.update

    arch.read

    artifact.create
    artifact.delete
    artifact.read
    artifact.update

    component.create
    component.delete
    component.read
    component.update

    channel.read

    constraint.read

    engine.read

    entitlement.create
    entitlement.delete
    entitlement.read
    entitlement.update

    environment.create
    environment.delete
    environment.read
    environment.tokens.generate
    environment.update

    event-log.read

    group.create
    group.delete
    group.licenses.read
    group.machines.read
    group.owners.attach
    group.owners.detach
    group.owners.read
    group.read
    group.update
    group.users.read

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
    license.group.update
    license.policy.update
    license.read
    license.reinstate
    license.renew
    license.revoke
    license.suspend
    license.tokens.generate
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
    machine.read
    machine.update

    metric.read

    package.create
    package.delete
    package.read
    package.update

    platform.read

    policy.create
    policy.delete
    policy.entitlements.attach
    policy.entitlements.detach
    policy.pool.pop
    policy.read
    policy.update

    process.create
    process.delete
    process.heartbeat.ping
    process.read
    process.update

    product.create
    product.delete
    product.read
    product.tokens.generate
    product.update

    release.constraints.attach
    release.constraints.detach
    release.create
    release.delete
    release.download
    release.package.update
    release.publish
    release.read
    release.update
    release.upgrade
    release.upload
    release.yank

    request-log.read

    token.generate
    token.read
    token.regenerate
    token.revoke

    user.ban
    user.create
    user.delete
    user.group.update
    user.invite
    user.password.reset
    user.password.update
    user.read
    user.second-factors.create
    user.second-factors.delete
    user.second-factors.read
    user.second-factors.update
    user.tokens.generate
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

  # Available env permissions.
  ENVIRONMENT_PERMISSIONS = %w[
    account.read

    arch.read

    artifact.create
    artifact.delete
    artifact.read
    artifact.update

    component.create
    component.delete
    component.read
    component.update

    channel.read

    constraint.read

    engine.read

    entitlement.create
    entitlement.delete
    entitlement.read
    entitlement.update

    environment.read

    event-log.read

    group.create
    group.delete
    group.licenses.read
    group.machines.read
    group.owners.attach
    group.owners.detach
    group.owners.read
    group.read
    group.update
    group.users.read

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
    license.group.update
    license.policy.update
    license.read
    license.reinstate
    license.renew
    license.revoke
    license.suspend
    license.tokens.generate
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
    machine.read
    machine.update

    package.create
    package.delete
    package.read
    package.update

    platform.read

    policy.create
    policy.delete
    policy.entitlements.attach
    policy.entitlements.detach
    policy.pool.pop
    policy.read
    policy.update

    process.create
    process.delete
    process.heartbeat.ping
    process.read
    process.update

    product.create
    product.delete
    product.read
    product.tokens.generate
    product.update

    release.constraints.attach
    release.constraints.detach
    release.create
    release.delete
    release.download
    release.package.update
    release.publish
    release.read
    release.update
    release.upgrade
    release.upload
    release.yank

    request-log.read

    token.generate
    token.read
    token.regenerate
    token.revoke

    user.ban
    user.create
    user.delete
    user.group.update
    user.invite
    user.password.reset
    user.password.update
    user.read
    user.second-factors.create
    user.second-factors.delete
    user.second-factors.read
    user.second-factors.update
    user.tokens.generate
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

  # Available admin permissions.
  ADMIN_PERMISSIONS = ALL_PERMISSIONS.dup
                                     .freeze

  # Available readonly permissions.
  READ_ONLY_PERMISSIONS =%w[
    account.analytics.read
    account.billing.read
    account.plan.read
    account.read
    account.subscription.read

    admin.read

    arch.read

    artifact.read

    component.read

    channel.read

    constraint.read

    engine.read

    entitlement.read

    environment.read

    event-log.read

    group.licenses.read
    group.machines.read
    group.owners.read
    group.read
    group.users.read

    key.read

    license.read
    license.validate

    machine.read

    metric.read

    package.read

    platform.read

    policy.read

    process.read

    product.read

    release.download
    release.read
    release.upgrade

    request-log.read

    token.generate
    token.read

    user.password.reset
    user.password.update
    user.read
    user.second-factors.read

    webhook-endpoint.read
    webhook-event.read
  ]

  # Available product permissions.
  PRODUCT_PERMISSIONS = %w[
    account.read

    arch.read

    artifact.create
    artifact.delete
    artifact.read
    artifact.update

    component.create
    component.delete
    component.read
    component.update

    channel.read

    constraint.read

    engine.read

    entitlement.read

    group.create
    group.delete
    group.licenses.read
    group.machines.read
    group.owners.attach
    group.owners.detach
    group.owners.read
    group.read
    group.update
    group.users.read

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
    license.group.update
    license.policy.update
    license.read
    license.reinstate
    license.renew
    license.revoke
    license.suspend
    license.tokens.generate
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
    machine.read
    machine.update

    package.create
    package.delete
    package.read
    package.update

    platform.read

    policy.create
    policy.delete
    policy.entitlements.attach
    policy.entitlements.detach
    policy.pool.pop
    policy.read
    policy.update

    process.create
    process.delete
    process.heartbeat.ping
    process.read
    process.update

    product.read
    product.update

    release.constraints.attach
    release.constraints.detach
    release.create
    release.delete
    release.download
    release.package.update
    release.publish
    release.read
    release.update
    release.upgrade
    release.upload
    release.yank

    token.generate
    token.read
    token.regenerate
    token.revoke

    user.ban
    user.create
    user.group.update
    user.read
    user.tokens.generate
    user.unban
    user.update

    webhook-endpoint.create
    webhook-endpoint.delete
    webhook-endpoint.read
    webhook-endpoint.update
    webhook-event.read
  ].freeze

  # Available user permissions.
  USER_PERMISSIONS = %w[
    account.read

    arch.read

    artifact.read

    component.create
    component.delete
    component.read
    component.update

    channel.read

    constraint.read

    engine.read

    entitlement.read

    group.licenses.read
    group.machines.read
    group.owners.read
    group.read
    group.users.read

    license.check-in
    license.check-out
    license.create
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

    package.read

    platform.read

    policy.read

    process.create
    process.delete
    process.heartbeat.ping
    process.read
    process.update

    product.read

    release.download
    release.read
    release.upgrade

    token.generate
    token.read
    token.regenerate
    token.revoke

    user.password.reset
    user.password.update
    user.read
    user.second-factors.create
    user.second-factors.delete
    user.second-factors.read
    user.second-factors.update
    user.update
  ].freeze

  # Available license permissions.
  LICENSE_PERMISSIONS = %w[
    account.read

    arch.read

    artifact.read

    component.create
    component.delete
    component.read
    component.update

    channel.read

    constraint.read

    engine.read

    entitlement.read

    group.owners.read
    group.read

    license.check-in
    license.check-out
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

    package.read

    platform.read

    policy.read

    process.create
    process.delete
    process.heartbeat.ping
    process.read
    process.update

    product.read

    release.download
    release.read
    release.upgrade

    token.read
    token.regenerate
    token.revoke

    user.read
  ].freeze

  ##
  # actions returns the actions of the permissions.
  def self.actions = reorder(action: :asc).pluck(:action)

  ##
  # wildcard returns the wildcard permission record.
  def self.wildcard = where(action: WILDCARD_PERMISSION).take

  ##
  # wildcard_id returns the wildcard permission ID.
  def self.wildcard_id = where(action: WILDCARD_PERMISSION).pick(:id)

  ##
  # wildcard? checks if any of the given IDs are the wildcard permission.
  def self.wildcard?(*identifiers)
    return true if
      identifiers.include?(WILDCARD_PERMISSION)

    exists?(id: identifiers, action: WILDCARD_PERMISSION)
  end

  ##
  # wildcard? checks if the current permission is the wildcard.
  def wildcard? = action == WILDCARD_PERMISSION
end
