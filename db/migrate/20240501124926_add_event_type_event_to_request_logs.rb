class AddEventTypeEventToRequestLogs < ActiveRecord::Migration[7.1]
  verbose!

  def change
    add_column :request_logs, :event_type_event, :string, null: true
    add_column :request_logs, :event_type_id,    :uuid,   null: true
  end
end
