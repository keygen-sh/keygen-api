class UpdateAnalyticsIndexesForRequestLogs < ActiveRecord::Migration[6.1]
  disable_ddl_transaction!

  def up
    remove_index :request_logs, [:requestor_id, :requestor_type, :created_at], if_exists: true
    remove_index :request_logs, [:resource_id, :resource_type, :created_at], if_exists: true

    add_index :request_logs, [:requestor_id, :requestor_type, :account_id, :created_at], where: 'requestor_id is not null and requestor_type is not null', name: :request_logs_top_requestor_idx, algorithm: :concurrently
    add_index :request_logs, [:resource_id, :resource_type, :account_id, :created_at], where: 'resource_id is not null and resource_type is not null', name: :request_logs_top_resource_idx, algorithm: :concurrently
    add_index :request_logs, [:method, :url, :account_id, :created_at], where: 'method is not null and url is not null', name: :request_logs_top_method_url_idx, algorithm: :concurrently
    add_index :request_logs, [:ip, :account_id, :created_at], where: 'ip is not null', name: :request_logs_top_ip_idx, algorithm: :concurrently
  end

  def down
    remove_index :request_logs, name: :request_logs_top_requestor_idx, if_exists: true
    remove_index :request_logs, name: :request_logs_top_resource_idx, if_exists: true
    remove_index :request_logs, name: :request_logs_top_method_url_idx, if_exists: true
    remove_index :request_logs, name: :request_logs_top_ip_idx, if_exists: true

    add_index :request_logs, [:requestor_id, :requestor_type, :created_at], name: :request_logs_requestor_idx, algorithm: :concurrently
    add_index :request_logs, [:resource_id, :resource_type, :created_at], name: :request_logs_resource_idx, algorithm: :concurrently
  end
end
