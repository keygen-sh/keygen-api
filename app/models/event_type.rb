# frozen_string_literal: true

class EventType < ApplicationRecord
  EVENT_TYPES = %w[
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
    *
  ].freeze

  def self.cache_key(event)
    [:event_types, event].join ":"
  end

  def cache_key
    EventType.cache_key event
  end

  def self.clear_cache!(event)
    key = EventType.cache_key event

    Rails.cache.delete key
  end

  def clear_cache!
    EventType.clear_cache! event
  end
end
