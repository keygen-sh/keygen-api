class AddSearchIndicesToRequestLogs < ActiveRecord::Migration[7.0]
  disable_ddl_transaction!

  def change
    add_index :request_logs, %i[method], name: :request_logs_method_idx, algorithm: :concurrently, if_not_exists: true
    add_index :request_logs, %i[status], name: :request_logs_status_idx, algorithm: :concurrently, if_not_exists: true
  end
end
