class UpdateResourceIndexForEventLogs < ActiveRecord::Migration[7.0]
  disable_ddl_transaction!

  def change
    remove_index :event_logs, %i[resource_type resource_id], algorithm: :concurrently, if_exists: true
    add_index :event_logs, %i[resource_type resource_id created_at],
      name: :event_logs_resource_crt_idx,
      order: { created_at: :desc },
      algorithm: :concurrently
  end
end
