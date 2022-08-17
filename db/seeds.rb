# frozen_string_literal: true

permissions = %w[
  *

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
  group.licenses.read
  group.machines.read
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
  license.group.read
  license.group.update
  license.machines.read
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
  machine.group.read
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
]

events = %w[
  *

  account.billing.updated
  account.plan.updated
  account.subscription.canceled
  account.subscription.paused
  account.subscription.renewed
  account.subscription.resumed
  account.updated

  artifact.created
  artifact.deleted
  artifact.downloaded
  artifact.updated
  artifact.uploaded

  entitlement.created
  entitlement.deleted
  entitlement.updated

  group.created
  group.deleted
  group.updated

  key.created
  key.deleted
  key.updated

  license.check-in-overdue
  license.check-in-required-soon
  license.checked-in
  license.checked-out
  license.created
  license.deleted
  license.entitlements.attached
  license.entitlements.detached
  license.expired
  license.expiring-soon
  license.group.updated
  license.permissions.attached
  license.permissions.detached
  license.policy.updated
  license.reinstated
  license.renewed
  license.revoked
  license.suspended
  license.updated
  license.usage.decremented
  license.usage.incremented
  license.usage.reset
  license.user.updated
  license.validated
  license.validation.failed
  license.validation.succeeded

  machine.checked-out
  machine.created
  machine.deleted
  machine.group.updated
  machine.heartbeat.dead
  machine.heartbeat.ping
  machine.heartbeat.pong
  machine.heartbeat.reset
  machine.heartbeat.resurrected
  machine.proofs.generated
  machine.updated

  policy.created
  policy.deleted
  policy.entitlements.attached
  policy.entitlements.detached
  policy.pool.popped
  policy.updated

  process.created
  process.deleted
  process.heartbeat.dead
  process.heartbeat.ping
  process.heartbeat.pong

  product.created
  product.deleted
  product.permissions.attached
  product.permissions.detached
  product.updated

  release.constraints.attached
  release.constraints.detached
  release.created
  release.deleted
  release.downloaded
  release.published
  release.replaced
  release.updated
  release.upgraded
  release.uploaded
  release.yanked

  second-factor.created
  second-factor.deleted
  second-factor.disabled
  second-factor.enabled

  token.generated
  token.regenerated
  token.revoked

  user.banned
  user.created
  user.deleted
  user.group.updated
  user.password-reset
  user.permissions.attached
  user.permissions.detached
  user.unbanned
  user.updated
]

Permission.upsert_all(
  permissions.map { |action| { action: } },
  record_timestamps: true,
  on_duplicate: :skip,
)

EventType.upsert_all(
  events.map { |event| { event: } },
  record_timestamps: true,
  on_duplicate: :skip,
)
