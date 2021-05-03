class RemoveGinIndexesFromRequestLogs < ActiveRecord::Migration[6.1]
  def up
    # NOTE(ezekg) https://iamsafts.com/posts/postgres-gin-performance/
    remove_index :request_logs, name: :request_logs_tsv_ip_idx
    remove_index :request_logs, name: :request_logs_tsv_request_id_idx
    remove_index :request_logs, name: :request_logs_tsv_requestor_id_idx
    remove_index :request_logs, name: :request_logs_tsv_resource_id_idx
    remove_index :request_logs, name: :index_request_logs_on_url
  end
end
