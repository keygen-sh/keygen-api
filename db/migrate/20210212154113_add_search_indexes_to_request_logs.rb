class AddSearchIndexesToRequestLogs < ActiveRecord::Migration[5.2]
  disable_ddl_transaction!

  def change
    add_index :request_logs, "to_tsvector('simple'::regconfig, (request_id)::text)", name: :request_logs_tsv_request_id_idx, algorithm: :concurrently, using: :gin
    add_index :request_logs, "to_tsvector('simple'::regconfig, (ip)::text)", name: :request_logs_tsv_ip_idx, algorithm: :concurrently, using: :gin
    add_index :request_logs, :url, algorithm: :concurrently, using: :gin
  end
end
