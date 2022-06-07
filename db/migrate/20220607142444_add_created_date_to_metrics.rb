class AddCreatedDateToMetrics < ActiveRecord::Migration[7.0]
  disable_ddl_transaction!

  LICENSE_VALIDATION_SUCCEEDED_EVENT_TYPE_ID = 'b4d4a9ff-1a63-4d5f-b95f-617788fb50dc'
  LICENSE_VALIDATION_FAILED_EVENT_TYPE_ID    = 'a0a302c6-2872-4983-b815-391a5022d469'
  MACHINE_HEARTBEAT_PING_EVENT_TYPE_ID       = '918f5d37-7369-454e-a5e5-9385a46f184a'
  MACHINE_HEARTBEAT_PONG_EVENT_TYPE_ID       = 'ac3e4f4b-712c-4cce-aa33-81788d4c4fbf'
  PROCESS_HEARTBEAT_PING_EVENT_TYPE_ID       = 'e84ab2b7-efd8-42f9-87be-1f3aa34b3e42'
  PROCESS_HEARTBEAT_PONG_EVENT_TYPE_ID       = '2634100c-40aa-4879-a84d-8d9878573efc'

  # High volume events need a separate index
  HIGH_VOLUME_EVENT_TYPE_IDS = [
    LICENSE_VALIDATION_SUCCEEDED_EVENT_TYPE_ID,
    LICENSE_VALIDATION_FAILED_EVENT_TYPE_ID,
    MACHINE_HEARTBEAT_PING_EVENT_TYPE_ID,
    MACHINE_HEARTBEAT_PONG_EVENT_TYPE_ID,
    PROCESS_HEARTBEAT_PING_EVENT_TYPE_ID,
    PROCESS_HEARTBEAT_PONG_EVENT_TYPE_ID,
  ].freeze

  def change
    add_column :metrics, :created_date, :date, null: true

    add_index :metrics, %i[account_id created_date],
      order: { created_date: :desc },
      algorithm: :concurrently

    add_index :metrics, %i[account_id created_date event_type_id],
      name: :metrics_lo_vol_acct_created_date_event_type_idx,
      where: "event_type_id NOT IN (#{HIGH_VOLUME_EVENT_TYPE_IDS.map { |id| Arel.sql(%('#{id}')) }.join(', ')})",
      order: { created_date: :desc },
      algorithm: :concurrently

    add_index :metrics, %i[account_id created_date event_type_id],
      name: :metrics_hi_vol_acct_created_date_event_type_idx,
      where: "event_type_id IN (#{HIGH_VOLUME_EVENT_TYPE_IDS.map { |id| Arel.sql(%('#{id}')) }.join(', ')})",
      order: { created_date: :desc },
      algorithm: :concurrently
  end
end
