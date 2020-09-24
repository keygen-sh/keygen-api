class AddEventTypeToMetrics < ActiveRecord::Migration[5.2]
  def up
    add_column :metrics, :event_type_id, :uuid, null: true

    # Update all metrics to have an event type association before
    # we add the foreign key constraint
    Metric.connection.update('
      UPDATE metrics AS m
        SET event_type_id = e.id
      FROM event_types AS e
        WHERE m.metric = e.event
    ')

    change_column :metrics, :event_type_id, :uuid, null: false

    add_foreign_key :metrics, :event_types
  end

  def down
    remove_column :metrics, :event_type_id
  end
end
