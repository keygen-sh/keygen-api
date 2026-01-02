class AddIsDeletedToEventLogs < ActiveRecord::Migration[8.1]
  def change
    add_column :event_logs, :is_deleted, :timestamp
  end
end
