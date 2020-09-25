class AddEventTypeToMetrics < ActiveRecord::Migration[5.2]
  disable_ddl_transaction!

  def up
    unless column_exists?(:metrics, :event_type_id)
      add_column :metrics, :event_type_id, :uuid, null: true
    end
    add_index :metrics, :event_type_id, algorithm: :concurrently
  end

  def down
    remove_column :metrics, :event_type_id
  end
end
