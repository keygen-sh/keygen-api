class ChangeIdIndexForRequestLogs < ActiveRecord::Migration[5.2]
  disable_ddl_transaction!

  def change
    remove_index :request_logs, [:id, :created_at]

    add_index :request_logs, [:request_id, :created_at], unique: true, algorithm: :concurrently
  end
end
