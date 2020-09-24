class CreateEventTypes < ActiveRecord::Migration[5.2]
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

  def up
    create_table :event_types, id: :uuid, default: -> { "uuid_generate_v4()" } do |t|
      t.string :event

      t.timestamps
    end

    add_index :event_types, :event, unique: true

    EventType.create!(
      EVENT_TYPES.map { |e| { event: e } }
    )
  end

  def down
    drop_table :event_types
  end
end
