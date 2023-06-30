class ReaddRequestorIndexToRequestLogs < ActiveRecord::Migration[7.0]
  disable_ddl_transaction!

  def change
    add_index :request_logs, %i[requestor_id requestor_type],
      name: :request_logs_requestor_idx,
      algorithm: :concurrently
  end
end
