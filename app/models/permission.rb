# frozen_string_literal: true

class Permission < ApplicationRecord
  has_many :role_permissions
  has_many :token_permissions
  has_many :group_permissions

  # The action name of the wildcard permission.
  WILDCARD_PERMISSION = '*'.freeze

  # Default admin permissions.
  ALL_PERMISSIONS   =
  ADMIN_PERMISSIONS = %w[
    account.billing.read
    account.billing.update
    account.plan.read
    account.plan.update
    account.read
    account.subscription.read
    account.subscription.update
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
    group.owners.attach
    group.owners.detach
    group.owners.read

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

    metric.read

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
    process.update

    product.create
    product.delete
    product.read
    product.tokens.generate
    product.tokens.read
    product.update

    platform.read

    release.constraints.attach
    release.constraints.detach
    release.constraints.read
    release.entitlements.read
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
    second-factor.read
    second-factor.update

    token.generate
    token.regenerate
    token.read
    token.revoke

    user.ban
    user.create
    user.delete
    user.group.update
    user.invite
    user.password.update
    user.password.reset
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

  # Default readonly permissions.
  READ_ONLY_PERMISSIONS =%w[
    account.billing.read
    account.plan.read
    account.read
    account.subscription.read

    arch.read

    artifact.download
    artifact.read

    channel.read

    entitlement.read

    event-log.read

    group.read
    group.owners.read

    key.read

    license.entitlements.read
    license.read
    license.tokens.read

    machine.read

    metric.read

    policy.entitlements.read
    policy.read

    process.read

    product.read
    product.tokens.read

    platform.read

    release.constraints.read
    release.entitlements.read
    release.download
    release.read
    release.upgrade

    request-log.read

    second-factor.create
    second-factor.delete
    second-factor.read
    second-factor.update

    token.generate
    token.read

    user.password.update
    user.password.reset
    user.read
    user.tokens.read

    webhook-endpoint.read

    webhook-event.read
  ]

  # Default product permissions.
  PRODUCT_PERMISSIONS = %w[
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
    group.owners.attach
    group.owners.detach
    group.owners.read

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
    process.update

    product.read
    product.update
    product.tokens.read

    platform.read

    release.constraints.attach
    release.constraints.detach
    release.constraints.read
    release.entitlements.read
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
    user.read
    user.tokens.generate
    user.tokens.read
    user.unban
    user.update

    webhook-event.read
  ].freeze

  # Default user permissions.
  USER_PERMISSIONS = %w[
    account.read

    arch.read

    artifact.download
    artifact.read

    channel.read

    group.read
    group.owners.read

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
    process.update

    product.read

    platform.read

    release.constraints.read
    release.download
    release.read
    release.upgrade

    second-factor.create
    second-factor.delete
    second-factor.read
    second-factor.update

    token.generate
    token.regenerate
    token.revoke
    token.read

    user.password.update
    user.password.reset
    user.read
    user.update
    user.tokens.read
  ].freeze

  # Default license permissions.
  LICENSE_PERMISSIONS = %w[
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
    process.update

    product.read

    platform.read

    release.constraints.read
    release.download
    release.read
    release.upgrade

    token.regenerate
    token.revoke
    token.read

    user.read
  ].freeze

  # wildcard returns the wildcard permission record.
  def self.wildcard    = find_by(action: WILDCARD_PERMISSION)
  def self.wildcard_id = wildcard.id

  # wildcard? checks if any of the given IDs are the wildcard permission.
  def self.wildcard?(*identifiers)
    return true if
      identifiers.include?(WILDCARD_PERMISSION)

    exists?(id: identifiers, action: WILDCARD_PERMISSION)
  end
end
