class RemoveNullableEventTypeForMetrics < ActiveRecord::Migration[5.2]
  def up
    change_column :metrics, :event_type_id, :uuid, null: false
  end

  def down
    change_column :metrics, :event_type_id, :uuid, null: true
  end
end
