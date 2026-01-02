# frozen_string_literal: true

class CreateRequestLogs < ActiveRecord::Migration[7.2]
  def up
    create_table :request_logs, id: false,
      options: "ReplacingMergeTree(_version) PARTITION BY toYYYYMM(created_date) ORDER BY (account_id, created_date, id)",
      force: :cascade do |t|
      # identifiers (null: false prevents gem from auto-wrapping in Nullable)
      t.column :id, "UUID", null: false
      t.column :account_id, "UUID", null: false
      t.column :environment_id, "Nullable(UUID)", null: false

      # timestamps
      t.column :created_at, "DateTime64(3, 'UTC')", null: false
      t.column :updated_at, "DateTime64(3, 'UTC')", null: false
      t.column :created_date, "Date", null: false

      # request metadata
      t.column :method, "LowCardinality(Nullable(String))", null: false
      t.column :status, "LowCardinality(Nullable(String))", null: false
      t.column :url, "Nullable(String)", null: false
      t.column :ip, "Nullable(String)", null: false
      t.column :user_agent, "Nullable(String)", null: false

      # polymorphic requestor
      t.column :requestor_type, "LowCardinality(Nullable(String))", null: false
      t.column :requestor_id, "Nullable(UUID)", null: false

      # polymorphic resource
      t.column :resource_type, "LowCardinality(Nullable(String))", null: false
      t.column :resource_id, "Nullable(UUID)", null: false

      # bodies (often excluded from queries via without_blobs scope)
      t.column :request_body, "Nullable(String)", null: false
      t.column :request_headers, "Nullable(String)", null: false
      t.column :response_body, "Nullable(String)", null: false
      t.column :response_headers, "Nullable(String)", null: false
      t.column :response_signature, "Nullable(String)", null: false

      # performance metrics
      t.column :queue_time, "Nullable(Float64)", null: false
      t.column :run_time, "Nullable(Float64)", null: false

      # version for ReplacingMergeTree deduplication
      t.column :_version, "UInt64 DEFAULT toUnixTimestamp64Milli(now64(3))", null: false
    end

    # secondary indexes
    add_index :request_logs, :status, name: "idx_status", type: "set(100)", granularity: 4
    add_index :request_logs, :method, name: "idx_method", type: "set(20)", granularity: 4
    add_index :request_logs, "(requestor_type, requestor_id)", name: "idx_requestor", type: "bloom_filter", granularity: 4
    add_index :request_logs, "(resource_type, resource_id)", name: "idx_resource", type: "bloom_filter", granularity: 4
    add_index :request_logs, :ip, name: "idx_ip", type: "bloom_filter", granularity: 4
    add_index :request_logs, :environment_id, name: "idx_environment", type: "bloom_filter", granularity: 4
  end

  def down
    drop_table :request_logs
  end
end
