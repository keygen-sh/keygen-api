class RemoveRequestIdFromRequestLogs < ActiveRecord::Migration[6.1]
  def change
    remove_column :request_logs, :request_id
  end
end
