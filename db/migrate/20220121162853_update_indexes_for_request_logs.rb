class UpdateIndexesForRequestLogs < ActiveRecord::Migration[6.1]
  disable_ddl_transaction!

  def change
    remove_index :request_logs, :request_logs_top_ip_idx, algorithm: :concurrently, if_exists: true
    remove_index :request_logs, :request_logs_top_method_url_idx, algorithm: :concurrently, if_exists: true
    remove_index :request_logs, :request_logs_request_id_created_idx, algorithm: :concurrently, if_exists: true
    remove_index :request_logs, :request_logs_top_requestor_idx, algorithm: :concurrently, if_exists: true
    remove_index :request_logs, :request_logs_top_resource_idx, algorithm: :concurrently, if_exists: true
    remove_index :request_logs, %i[account_id created_at], algorithm: :concurrently, if_exists: true

    # NOTE(ezekg) Account ID is first so that the index can work on a
    #             smaller dataset before filtering by created at.
    add_index :request_logs, %i[account_id created_at], algorithm: :concurrently
  end
end
