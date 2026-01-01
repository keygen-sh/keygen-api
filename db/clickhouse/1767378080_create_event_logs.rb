# frozen_string_literal: true

class CreateEventLogs < ActiveRecord::Migration[8.1]
  def up
    create_table :event_logs, id: false,
      options: 'ReplacingMergeTree(ver, is_deleted) PARTITION BY toYYYYMMDD(created_date) ORDER BY (account_id, created_date, id)',
      ttl: 'created_at + INTERVAL ttl SECOND',
      force: :cascade do |t|
      # identifiers
      t.uuid :id, null: false
      t.uuid :account_id, null: false
      t.uuid :environment_id, null: true
      t.uuid :event_type_id, null: false
      t.uuid :request_log_id, null: true

      # timestamps
      t.datetime :created_at, precision: 3, null: false
      t.datetime :updated_at, precision: 3, null: false
      t.date :created_date, null: false

      # polymorphic resource (required)
      t.string :resource_type, low_cardinality: true, null: false
      t.uuid :resource_id, null: false

      # polymorphic whodunnit (optional)
      t.string :whodunnit_type, low_cardinality: true, null: true
      t.uuid :whodunnit_id, null: true

      # event data
      t.string :idempotency_key, null: true
      t.json :metadata, null: true, ttl: 'created_at + INTERVAL 30 DAY'

      # soft delete flag for ReplacingMergeTree
      t.column :is_deleted, "UInt8", null: false, default: 0

      # version for ReplacingMergeTree deduplication
      t.datetime :ver, precision: 3, null: false, default: -> { "now()" }

      # TTL in seconds (set per-account at insert time)
      t.column :ttl, "UInt32", null: false, default: 30.days.to_i
    end

    # secondary indexes
    add_index :event_logs, :event_type_id, name: "idx_event_type", type: "bloom_filter", granularity: 4
    add_index :event_logs, "(resource_type, resource_id)", name: "idx_resource", type: "bloom_filter", granularity: 4
    add_index :event_logs, "(whodunnit_type, whodunnit_id)", name: "idx_whodunnit", type: "bloom_filter", granularity: 4
    add_index :event_logs, :request_log_id, name: "idx_request_log", type: "bloom_filter", granularity: 4
    add_index :event_logs, :environment_id, name: "idx_environment", type: "bloom_filter", granularity: 4
    add_index :event_logs, :idempotency_key, name: "idx_idempotency", type: "bloom_filter", granularity: 4
  end

  def down
    drop_table :event_logs
  end
end
