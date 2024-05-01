class AddEventTypeEventToEventLogs < ActiveRecord::Migration[7.1]
  verbose!

  def change
    add_column :event_logs, :event_type_event, :string, null: true
  end
end
