class AddIsDeletedToRequestLogs < ActiveRecord::Migration[8.1]
  def change
    add_column :request_logs, :is_deleted, :timestamp
  end
end
