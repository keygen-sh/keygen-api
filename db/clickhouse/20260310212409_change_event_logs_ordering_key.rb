# frozen_string_literal: true

class ChangeEventLogsOrderingKey < ActiveRecord::Migration[8.1]
  verbose!

  def up
    # clickhouse doesn't natively order UUIDv7 correctly so we're using UUIDToNum(id)
    # to ensure proper ordering by timestamp-embedded UUIDs
    create_table :event_logs_tmp, id: false,
      options: 'ReplacingMergeTree(ver, is_deleted) PARTITION BY toYYYYMM(created_date) ORDER BY (account_id, created_date, UUIDToNum(id))',
      ttl: 'created_at + INTERVAL ttl SECOND',
      force: :cascade do |t|
      t.uuid :id, null: false
      t.uuid :account_id, null: false
      t.uuid :environment_id, null: true
      t.uuid :event_type_id, null: false
      t.uuid :request_log_id, null: true

      t.datetime :created_at, precision: 3, null: false
      t.datetime :updated_at, precision: 3, null: false
      t.date :created_date, null: false

      t.string :resource_type, low_cardinality: true, null: false
      t.uuid :resource_id, null: false

      t.string :whodunnit_type, low_cardinality: true, null: true
      t.uuid :whodunnit_id, null: true

      t.string :idempotency_key, null: true
      t.json :metadata, null: true, ttl: 'created_at + INTERVAL 30 DAY'

      t.column :is_deleted, 'UInt8', null: false, default: 0
      t.datetime :ver, precision: 3, null: false, default: -> { 'now()' }
      t.column :ttl, 'UInt32', null: false, default: 30.days.to_i
    end

    add_index :event_logs_tmp, :event_type_id, name: 'idx_event_type', type: 'bloom_filter', granularity: 4
    add_index :event_logs_tmp, '(resource_type, resource_id)', name: 'idx_resource', type: 'bloom_filter', granularity: 4
    add_index :event_logs_tmp, '(whodunnit_type, whodunnit_id)', name: 'idx_whodunnit', type: 'bloom_filter', granularity: 4
    add_index :event_logs_tmp, :request_log_id, name: 'idx_request_log', type: 'bloom_filter', granularity: 4
    add_index :event_logs_tmp, :environment_id, name: 'idx_environment', type: 'bloom_filter', granularity: 4
    add_index :event_logs_tmp, :idempotency_key, name: 'idx_idempotency', type: 'bloom_filter', granularity: 4
    add_index :event_logs_tmp, :id, name: 'idx_id', type: 'bloom_filter', granularity: 4

    # atomically swap so event_logs gets the new layout and event_logs_tmp
    # retains the old data for backfilling
    execute 'EXCHANGE TABLES event_logs AND event_logs_tmp'
  end

  def down
    execute 'EXCHANGE TABLES event_logs AND event_logs_tmp'
  end
end
