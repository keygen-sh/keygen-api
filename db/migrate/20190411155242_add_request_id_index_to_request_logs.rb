class AddRequestIdIndexToRequestLogs < ActiveRecord::Migration[5.2]
  disable_ddl_transaction!

  def change
    add_index :request_logs, [:request_id, :created_at], algorithm: :concurrently
  end
end
