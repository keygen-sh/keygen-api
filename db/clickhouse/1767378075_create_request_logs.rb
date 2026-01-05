# frozen_string_literal: true

class CreateRequestLogs < ActiveRecord::Migration[8.1]
  def up
    create_table :request_logs, id: false,
      options: "ReplacingMergeTree(ver, is_deleted) PARTITION BY toYYYYMMDD(created_date) ORDER BY (account_id, created_date, id)",
      force: :cascade do |t|
      # identifiers
      t.uuid :id, null: false
      t.uuid :account_id, null: false
      t.uuid :environment_id, null: true

      # timestamps
      t.datetime :created_at, precision: 3, null: false
      t.datetime :updated_at, precision: 3, null: false
      t.date :created_date, null: false

      # request metadata
      t.string :method, low_cardinality: true, null: true
      t.string :status, low_cardinality: true, null: true
      t.string :url, null: true
      t.string :ip, null: true
      t.string :user_agent, null: true

      # polymorphic requestor
      t.string :requestor_type, low_cardinality: true, null: true
      t.uuid :requestor_id, null: true

      # polymorphic resource
      t.string :resource_type, low_cardinality: true, null: true
      t.uuid :resource_id, null: true

      # bodies (often excluded from queries via without_blobs scope)
      t.text :request_body, null: true, codec: 'ZSTD'
      t.json :request_headers, null: true
      t.text :response_body, null: true, codec: 'ZSTD'
      t.json :response_headers, null: true
      t.text :response_signature, null: true, codec: 'ZSTD'

      # performance metrics
      t.float :queue_time, null: true
      t.float :run_time, null: true

      # soft delete flag for ReplacingMergeTree
      # FIXME(ezekg) use int and limit: 8?
      t.column :is_deleted, "UInt8", null: false, default: 0

      # version for ReplacingMergeTree deduplication
      t.datetime :ver, null: false, default: -> { "now()" }

      # TTL in seconds (set per-account at insert time)
      t.column :ttl, "UInt32", null: false, default: 30.days.to_i
    end

    # Set TTL based on created_at + ttl seconds
    execute "ALTER TABLE request_logs MODIFY TTL created_at + INTERVAL ttl SECOND"

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
