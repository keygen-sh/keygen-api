class AddCreatedDateToRequestLogs < ActiveRecord::Migration[6.1]
  disable_ddl_transaction!

  def change
    add_column :request_logs, :created_date, :date
    add_index :request_logs, [:account_id, :created_date], algorithm: :concurrently
  end
end
