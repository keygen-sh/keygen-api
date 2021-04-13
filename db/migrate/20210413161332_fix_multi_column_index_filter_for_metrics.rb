class FixMultiColumnIndexFilterForMetrics < ActiveRecord::Migration[6.1]
  disable_ddl_transaction!

  LICENSE_VALIDATION_SUCCEEDED_EVENT_TYPE_ID = 'b4d4a9ff-1a63-4d5f-b95f-617788fb50dc'
  LICENSE_VALIDATION_FAILED_EVENT_TYPE_ID = 'a0a302c6-2872-4983-b815-391a5022d469'
  MACHINE_HEARTBEAT_PING_EVENT_TYPE_ID = '918f5d37-7369-454e-a5e5-9385a46f184a'
  MACHINE_HEARTBEAT_PONG_EVENT_TYPE_ID = 'ac3e4f4b-712c-4cce-aa33-81788d4c4fbf'
  MACHINE_HEARTBEAT_DEAD_EVENT_TYPE_ID = '7b14b995-2a2b-4f1f-9628-16a3bc9e8d76'
  TOKEN_GENERATED_EVENT_TYPE_ID = 'cbd8b04c-1fd7-41b9-b11d-74c9deb60c77'
  TOKEN_REGENERATED_EVENT_TYPE_ID = 'b4e5d6f2-25ff-46fb-9e1e-91ead72c0ccc'
  TOKEN_REVOKED_EVENT_TYPE_ID = 'ebb19f81-ca0f-4af4-bdbe-7476b22778ba'
  WILDCARD_EVENT_TYPE_ID = '6f75f2c4-6451-405a-a389-fa029137f6f0'

  # To reduce bloat, we don't really care about these event types since we do
  # not currently include them in any dashboard filters.
  FILTERED_EVENT_TYPE_IDS = [
    LICENSE_VALIDATION_SUCCEEDED_EVENT_TYPE_ID,
    LICENSE_VALIDATION_FAILED_EVENT_TYPE_ID,
    MACHINE_HEARTBEAT_PING_EVENT_TYPE_ID,
    MACHINE_HEARTBEAT_PONG_EVENT_TYPE_ID,
    MACHINE_HEARTBEAT_DEAD_EVENT_TYPE_ID,
    TOKEN_GENERATED_EVENT_TYPE_ID,
    TOKEN_REGENERATED_EVENT_TYPE_ID,
    TOKEN_REVOKED_EVENT_TYPE_ID,
    WILDCARD_EVENT_TYPE_ID,
  ].freeze

  def change
    remove_index :metrics, name: :metrics_account_created_event_type_idx

    add_index :metrics, [:account_id, :created_at, :event_type_id], {
      name: :metrics_account_created_event_type_idx,
      where: "event_type_id NOT IN (#{FILTERED_EVENT_TYPE_IDS.map { |id| Arel.sql("'#{id}'") }.join(', ')})",
      order: { created_at: :desc },
      algorithm: :concurrently
    }
  end
end
