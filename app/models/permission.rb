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
    key.policy.read
    key.product.read
    key.read
    key.update

    license.check-in
    license.check-out
    license.create
    license.delete
    license.entitlements.attach
    license.entitlements.detach
    license.entitlements.read
    license.group.read
    license.group.update
    license.machines.read
    license.policy.read
    license.policy.update
    license.product.read
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
    license.user.read
    license.user.update
    license.validate

    machine.check-out
    machine.create
    machine.delete
    machine.group.read
    machine.group.update
    machine.heartbeat.ping
    machine.heartbeat.reset
    machine.license.read
    machine.processes.read
    machine.product.read
    machine.proofs.generate
    machine.read
    machine.update
    machine.user.read

    metric.read

    platform.read
    policy.create
    policy.delete
    policy.entitlements.attach
    policy.entitlements.detach
    policy.entitlements.read
    policy.licenses.read
    policy.pool.pop
    policy.pool.read
    policy.product.read
    policy.read
    policy.update

    process.create
    process.delete
    process.heartbeat.ping
    process.license.read
    process.machine.read
    process.product.read
    process.read
    process.update

    product.arches.read
    product.artifacts.read
    product.channels.read
    product.create
    product.delete
    product.licenses.read
    product.machines.read
    product.platforms.read
    product.policies.read
    product.read
    product.releases.read
    product.tokens.generate
    product.tokens.read
    product.update
    product.users.read

    release.artifacts.read
    release.constraints.attach
    release.constraints.detach
    release.constraints.read
    release.create
    release.delete
    release.download
    release.entitlements.read
    release.entitlements.read
    release.product.read
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
    user.group.read
    user.group.update
    user.invite
    user.licenses.read
    user.machines.read
    user.password.reset
    user.password.update
    user.products.read
    user.read
    user.second-factors.create
    user.second-factors.delete
    user.second-factors.read
    user.second-factors.update
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

    arch.read

    artifact.download
    artifact.read

    channel.read

    entitlement.read

    event-log.read

    group.licenses.read
    group.machines.read
    group.owners.read
    group.read
    group.users.read

    key.policy.read
    key.product.read
    key.read

    license.entitlements.read
    license.group.read
    license.machines.read
    license.policy.read
    license.product.read
    license.read
    license.tokens.read
    license.user.read

    machine.group.read
    machine.license.read
    machine.processes.read
    machine.product.read
    machine.read
    machine.user.read

    metric.read

    platform.read

    policy.entitlements.read
    policy.licenses.read
    policy.product.read
    policy.read

    process.read

    product.arches.read
    product.artifacts.read
    product.channels.read
    product.licenses.read
    product.machines.read
    product.platforms.read
    product.policies.read
    product.read
    product.releases.read
    product.tokens.read
    product.users.read

    release.artifacts.read
    release.constraints.read
    release.download
    release.entitlements.read
    release.product.read
    release.read
    release.upgrade

    request-log.read

    token.generate
    token.read

    user.group.read
    user.licenses.read
    user.machines.read
    user.password.reset
    user.password.update
    user.products.read
    user.read
    user.second-factors.read
    user.tokens.read

    webhook-endpoint.read
    webhook-event.read
  ]

  # Available product permissions.
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
    key.policy.read
    key.product.read
    key.read
    key.update

    license.check-in
    license.check-out
    license.create
    license.delete
    license.entitlements.attach
    license.entitlements.detach
    license.entitlements.read
    license.group.read
    license.group.update
    license.machines.read
    license.policy.read
    license.policy.update
    license.product.read
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
    license.user.read
    license.user.update
    license.validate

    machine.check-out
    machine.create
    machine.delete
    machine.group.read
    machine.group.update
    machine.heartbeat.ping
    machine.heartbeat.reset
    machine.license.read
    machine.processes.read
    machine.product.read
    machine.proofs.generate
    machine.read
    machine.update
    machine.user.read

    platform.read

    policy.create
    policy.delete
    policy.entitlements.attach
    policy.entitlements.detach
    policy.entitlements.read
    policy.licenses.read
    policy.pool.pop
    policy.pool.read
    policy.product.read
    policy.read
    policy.update

    process.create
    process.delete
    process.heartbeat.ping
    process.license.read
    process.machine.read
    process.product.read
    process.read
    process.update

    product.arches.read
    product.artifacts.read
    product.channels.read
    product.licenses.read
    product.machines.read
    product.platforms.read
    product.policies.read
    product.read
    product.releases.read
    product.tokens.read
    product.update
    product.users.read

    release.artifacts.read
    release.constraints.attach
    release.constraints.detach
    release.constraints.read
    release.create
    release.delete
    release.download
    release.entitlements.read
    release.product.read
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
    user.group.read
    user.group.update
    user.licenses.read
    user.machines.read
    user.products.read
    user.read
    user.tokens.generate
    user.tokens.read
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

    artifact.download

    artifact.read

    channel.read

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
    license.entitlements.read
    license.group.read
    license.machines.read
    license.policy.read
    license.policy.update
    license.product.read
    license.read
    license.renew
    license.revoke
    license.usage.increment
    license.user.read
    license.validate

    machine.check-out
    machine.create
    machine.delete
    machine.group.read
    machine.heartbeat.ping
    machine.license.read
    machine.processes.read
    machine.product.read
    machine.proofs.generate
    machine.read
    machine.update
    machine.user.read

    platform.read

    policy.read

    process.create
    process.delete
    process.heartbeat.ping
    process.license.read
    process.machine.read
    process.product.read
    process.read
    process.update

    product.arches.read
    product.artifacts.read
    product.channels.read
    product.platforms.read
    product.read
    product.releases.read

    release.artifacts.read
    release.constraints.read
    release.download
    release.entitlements.read
    release.product.read
    release.read
    release.upgrade

    token.generate
    token.read
    token.regenerate
    token.revoke

    user.group.read
    user.licenses.read
    user.machines.read
    user.password.reset
    user.password.update
    user.products.read
    user.read
    user.second-factors.create
    user.second-factors.delete
    user.second-factors.read
    user.second-factors.update
    user.tokens.read
    user.update
  ].freeze

  # Available license permissions.
  LICENSE_PERMISSIONS = %w[
    account.read

    arch.read

    artifact.download
    artifact.read

    channel.read

    entitlement.read

    group.owners.read
    group.read

    license.check-in
    license.check-out
    license.entitlements.read
    license.group.read
    license.machines.read
    license.policy.read
    license.product.read
    license.read
    license.usage.increment
    license.user.read
    license.validate

    machine.check-out
    machine.create
    machine.delete
    machine.group.read
    machine.heartbeat.ping
    machine.license.read
    machine.processes.read
    machine.product.read
    machine.proofs.generate
    machine.read
    machine.update
    machine.user.read

    platform.read

    policy.read

    process.create
    process.delete
    process.heartbeat.ping
    process.license.read
    process.machine.read
    process.product.read
    process.read
    process.update

    product.arches.read
    product.artifacts.read
    product.channels.read
    product.platforms.read
    product.read
    product.releases.read

    release.artifacts.read
    release.constraints.read
    release.download
    release.entitlements.read
    release.product.read
    release.read
    release.upgrade

    token.read
    token.regenerate
    token.revoke

    user.read
  ].freeze

  # wildcard returns the wildcard permission record.
  def self.wildcard = where(action: WILDCARD_PERMISSION).take

  # wildcard_id returns the wildcard permission ID.
  def self.wildcard_id = where(action: WILDCARD_PERMISSION).pick(:id)

  # wildcard? checks if any of the given IDs are the wildcard permission.
  def self.wildcard?(*identifiers)
    return true if
      identifiers.include?(WILDCARD_PERMISSION)

    exists?(id: identifiers, action: WILDCARD_PERMISSION)
  end
end
