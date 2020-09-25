class AddEventTypeToWebhookEvents < ActiveRecord::Migration[5.2]
  disable_ddl_transaction!

  def up
    unless column_exists?(:webhook_events, :event_type_id)
      add_column :webhook_events, :event_type_id, :uuid, null: true
    end
    add_index :webhook_events, :event_type_id, algorithm: :concurrently
  end

  def down
    remove_column :webhook_events, :event_type_id
  end
end
