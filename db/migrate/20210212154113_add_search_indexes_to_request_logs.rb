class AddSearchIndexesToRequestLogs < ActiveRecord::Migration[5.2]
  disable_ddl_transaction!

  def change
    add_index :request_logs, :request_id, name: :request_logs_tsv_request_id_idx, algorithm: :concurrently, using: :gin
    add_index :request_logs, :url, name: :request_logs_tsv_url_idx, algorithm: :concurrently, using: :gin
    add_index :request_logs, :ip, name: :request_logs_tsv_ip_idx, algorithm: :concurrently, using: :gin
  end
end
