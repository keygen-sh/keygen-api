# frozen_string_literal: true

class CreateEventLogs < ActiveRecord::Migration[7.2]
  def up
    create_table :event_logs, id: false,
      options: "ReplacingMergeTree(_version) PARTITION BY toYYYYMM(created_date) ORDER BY (account_id, created_date, id)",
      force: :cascade do |t|
      # identifiers (null: false prevents gem from auto-wrapping in Nullable)
      t.column :id, "UUID", null: false
      t.column :account_id, "UUID", null: false
      t.column :environment_id, "Nullable(UUID)", null: false
      t.column :event_type_id, "UUID", null: false
      t.column :request_log_id, "Nullable(UUID)", null: false

      # timestamps
      t.column :created_at, "DateTime64(3, 'UTC')", null: false
      t.column :updated_at, "DateTime64(3, 'UTC')", null: false
      t.column :created_date, "Date", null: false

      # polymorphic resource (required)
      t.column :resource_type, "LowCardinality(String)", null: false
      t.column :resource_id, "UUID", null: false

      # polymorphic whodunnit (optional)
      t.column :whodunnit_type, "LowCardinality(Nullable(String))", null: false
      t.column :whodunnit_id, "Nullable(UUID)", null: false

      # event data
      t.column :idempotency_key, "Nullable(String)", null: false
      t.column :metadata, "Nullable(String)", null: false

      # version for ReplacingMergeTree deduplication
      t.column :_version, "UInt64 DEFAULT toUnixTimestamp64Milli(now64(3))", null: false
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
