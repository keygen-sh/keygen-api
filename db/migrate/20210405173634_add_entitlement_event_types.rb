class AddEntitlementEventTypes < ActiveRecord::Migration[6.1]
  EVENT_TYPES = %w[
    policy.entitlements.attached
    policy.entitlements.detached
    license.entitlements.attached
    license.entitlements.detached
    entitlement.created
    entitlement.updated
    entitlement.deleted
  ].freeze

  def up
    t = Time.current

    EventType.insert_all(EVENT_TYPES.map { |e| { event: e, created_at: t, updated_at: t } })
  end

  def down
    EventType.where(event: EVENT_TYPES).delete_all
  end
end
