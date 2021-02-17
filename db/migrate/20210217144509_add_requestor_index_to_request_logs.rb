class AddRequestorIndexToRequestLogs < ActiveRecord::Migration[5.2]
  disable_ddl_transaction!

  def change
    add_index :request_logs, "to_tsvector('simple'::regconfig, (requestor_id)::text)", name: :request_logs_tsv_requestor_id_idx, algorithm: :concurrently, using: :gin
    add_index :request_logs, [:requestor_id, :requestor_type, :created_at], name: :request_logs_requestor_idx, algorithm: :concurrently
  end
end
