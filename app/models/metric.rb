# frozen_string_literal: true

class Metric < ApplicationRecord
  include DateRangeable
  include Limitable
  include Pageable

  METRIC_TYPES = %w[
    account.updated
    account.subscription.paused
    account.subscription.resumed
    account.subscription.canceled
    account.subscription.renewed
    account.plan.updated
    account.billing.updated
    user.created
    user.updated
    user.deleted
    user.password-reset
    product.created
    product.updated
    product.deleted
    policy.created
    policy.updated
    policy.deleted
    policy.pool.popped
    policy.entitlements.attached
    policy.entitlements.detached
    license.created
    license.updated
    license.deleted
    license.expiring-soon
    license.expired
    license.checked-in
    license.check-in-required-soon
    license.check-in-overdue
    license.validation.succeeded
    license.validation.failed
    license.usage.incremented
    license.usage.decremented
    license.usage.reset
    license.renewed
    license.revoked
    license.suspended
    license.reinstated
    license.policy.updated
    license.user.updated
    license.entitlements.attached
    license.entitlements.detached
    machine.created
    machine.updated
    machine.deleted
    machine.heartbeat.ping
    machine.heartbeat.pong
    machine.heartbeat.dead
    key.created
    key.updated
    key.deleted
    token.generated
    token.regenerated
    token.revoked
    entitlement.created
    entitlement.updated
    entitlement.deleted
  ].freeze

  belongs_to :account
  belongs_to :event_type

  validates :account, presence: { message: "must exist" }
  validates :event_type, presence: { message: "must exist" }
  validates :data, presence: true

  # TODO(ezekg) Rename metrics => events
  scope :metrics, -> (*events) { where(event_type_id: EventType.where(event: events).pluck(:id)) }
  scope :current_period, -> {
    date_start = 2.weeks.ago.beginning_of_day
    date_end = Time.current

    where created_at: (date_start..date_end)
  }
end
