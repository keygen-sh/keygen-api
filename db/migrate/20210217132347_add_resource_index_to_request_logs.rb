class AddResourceIndexToRequestLogs < ActiveRecord::Migration[5.2]
  disable_ddl_transaction!

  def change
    add_index :request_logs, "to_tsvector('simple'::regconfig, (resource_id)::text)", name: :request_logs_tsv_resource_id_idx, algorithm: :concurrently, using: :gin
    add_index :request_logs, [:resource_id, :resource_type, :created_at], name: :request_logs_resource_idx, algorithm: :concurrently
  end
end
