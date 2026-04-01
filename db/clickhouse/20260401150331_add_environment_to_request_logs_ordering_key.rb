# frozen_string_literal: true

class AddEnvironmentToRequestLogsOrderingKey < ActiveRecord::Migration[8.1]
  verbose!

  def up
    # add environment_id to the ordering key so that environment-scoped queries
    # (especially environment_id IS NULL) benefit from primary index pruning
    # instead of post-scan filtering across all granules for an account.
    create_table :request_logs_tmp, id: false,
      options: 'ReplacingMergeTree(ver, is_deleted) PARTITION BY toYYYYMM(created_date) ORDER BY (account_id, environment_id, created_date, UUIDToNum(id))',
      ttl: 'created_at + INTERVAL ttl SECOND',
      settings: 'allow_nullable_key = 1, index_granularity = 8192',
      force: :cascade do |t|
      t.uuid :id, null: false
      t.uuid :account_id, null: false
      t.uuid :environment_id, null: true

      t.datetime :created_at, precision: 3, null: false
      t.datetime :updated_at, precision: 3, null: false
      t.date :created_date, null: false

      t.string :method, low_cardinality: true, null: true
      t.string :status, low_cardinality: true, null: true
      t.string :url, null: true
      t.string :ip, null: true, ttl: 'created_at + INTERVAL 30 DAY'
      t.string :user_agent, null: true, ttl: 'created_at + INTERVAL 30 DAY'

      t.string :requestor_type, low_cardinality: true, null: true
      t.uuid :requestor_id, null: true

      t.string :resource_type, low_cardinality: true, null: true
      t.uuid :resource_id, null: true

      t.text :request_body, null: true, codec: 'ZSTD', ttl: 'created_at + INTERVAL 30 DAY'
      t.json :request_headers, null: true, ttl: 'created_at + INTERVAL 30 DAY'
      t.text :response_body, null: true, codec: 'ZSTD', ttl: 'created_at + INTERVAL 30 DAY'
      t.json :response_headers, null: true, ttl: 'created_at + INTERVAL 30 DAY'
      t.text :response_signature, null: true, codec: 'ZSTD', ttl: 'created_at + INTERVAL 30 DAY'

      t.float :queue_time, null: true
      t.float :run_time, null: true

      t.column :is_deleted, 'UInt8', null: false, default: 0
      t.datetime :ver, precision: 3, null: false, default: -> { 'now()' }
      t.column :ttl, 'UInt32', null: false, default: 30.days.to_i
    end

    add_index :request_logs_tmp, :status, name: 'idx_status', type: 'set(100)', granularity: 4
    add_index :request_logs_tmp, :method, name: 'idx_method', type: 'set(20)', granularity: 4
    add_index :request_logs_tmp, '(requestor_type, requestor_id)', name: 'idx_requestor', type: 'bloom_filter', granularity: 4
    add_index :request_logs_tmp, '(resource_type, resource_id)', name: 'idx_resource', type: 'bloom_filter', granularity: 4
    add_index :request_logs_tmp, :ip, name: 'idx_ip', type: 'bloom_filter', granularity: 4
    add_index :request_logs_tmp, :id, name: 'idx_id', type: 'bloom_filter', granularity: 4

    # atomically swap so request_logs gets the new layout and request_logs_tmp
    # retains the old data for backfilling
    execute 'EXCHANGE TABLES request_logs AND request_logs_tmp'
  end

  def down
    execute 'EXCHANGE TABLES request_logs AND request_logs_tmp'
  end
end
