# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[8.1].define(version: 2026_02_25_054911) do
  # TABLE: active_licensed_user_sparks
  # SQL: CREATE TABLE active_licensed_user_sparks ( `account_id` UUID, `environment_id` Nullable(UUID), `count` UInt64 DEFAULT 0, `created_date` Date, `created_at` DateTime64(3) ) ENGINE = MergeTree PARTITION BY toYYYYMM(created_date) ORDER BY (account_id, created_date, environment_id) SETTINGS allow_nullable_key = 1, index_granularity = 8192
  create_table "active_licensed_user_sparks", id: false, options: "MergeTree PARTITION BY toYYYYMM(created_date) ORDER BY (account_id, created_date, environment_id) SETTINGS allow_nullable_key = 1, index_granularity = 8192", force: :cascade do |t|
    t.uuid "account_id", null: false
    t.uuid "environment_id"
    t.integer "count", limit: 8, default: 0, null: false
    t.date "created_date", null: false
    t.datetime "created_at", precision: 3, null: false
  end

  # TABLE: event_logs
  # SQL: CREATE TABLE event_logs ( `id` UUID, `account_id` UUID, `environment_id` Nullable(UUID), `event_type_id` UUID, `request_log_id` Nullable(UUID), `created_at` DateTime64(3), `updated_at` DateTime64(3), `created_date` Date, `resource_type` LowCardinality(String), `resource_id` UUID, `whodunnit_type` LowCardinality(Nullable(String)), `whodunnit_id` Nullable(UUID), `idempotency_key` Nullable(String), `metadata` Nullable(JSON) TTL created_at + toIntervalDay(30), `is_deleted` UInt8 DEFAULT 0, `ver` DateTime64(3) DEFAULT now(), `ttl` UInt32 DEFAULT 2592000, INDEX idx_event_type event_type_id TYPE bloom_filter GRANULARITY 4, INDEX idx_resource (resource_type, resource_id) TYPE bloom_filter GRANULARITY 4, INDEX idx_whodunnit (whodunnit_type, whodunnit_id) TYPE bloom_filter GRANULARITY 4, INDEX idx_request_log request_log_id TYPE bloom_filter GRANULARITY 4, INDEX idx_environment environment_id TYPE bloom_filter GRANULARITY 4, INDEX idx_idempotency idempotency_key TYPE bloom_filter GRANULARITY 4, INDEX idx_id id TYPE bloom_filter GRANULARITY 4 ) ENGINE = ReplacingMergeTree(ver, is_deleted) PARTITION BY toYYYYMMDD(created_date) ORDER BY (account_id, created_date, id) TTL created_at + toIntervalSecond(ttl) SETTINGS index_granularity = 8192
  create_table "event_logs", id: :uuid, options: "ReplacingMergeTree(ver, is_deleted) PARTITION BY toYYYYMMDD(created_date) ORDER BY (account_id, created_date, id) TTL created_at + toIntervalSecond(ttl) SETTINGS index_granularity = 8192", force: :cascade do |t|
    t.uuid "id", null: false
    t.uuid "account_id", null: false
    t.uuid "environment_id"
    t.uuid "event_type_id", null: false
    t.uuid "request_log_id"
    t.datetime "created_at", precision: 3, null: false
    t.datetime "updated_at", precision: 3, null: false
    t.date "created_date", null: false
    t.string "resource_type", low_cardinality: true, null: false
    t.uuid "resource_id", null: false
    t.string "whodunnit_type", low_cardinality: true
    t.uuid "whodunnit_id"
    t.string "idempotency_key"
    t.json "metadata", ttl: "created_at + toIntervalDay(30)"
    t.integer "is_deleted", limit: 1, default: 0, null: false
    t.datetime "ver", precision: 3, default: -> { "now()" }, null: false
    t.integer "ttl", default: 2592000, null: false

    t.index "event_type_id", name: "idx_event_type", type: "bloom_filter", granularity: 4
    t.index "(resource_type, resource_id)", name: "idx_resource", type: "bloom_filter", granularity: 4
    t.index "(whodunnit_type, whodunnit_id)", name: "idx_whodunnit", type: "bloom_filter", granularity: 4
    t.index "request_log_id", name: "idx_request_log", type: "bloom_filter", granularity: 4
    t.index "environment_id", name: "idx_environment", type: "bloom_filter", granularity: 4
    t.index "idempotency_key", name: "idx_idempotency", type: "bloom_filter", granularity: 4
    t.index "id", name: "idx_id", type: "bloom_filter", granularity: 4
  end

  # TABLE: license_sparks
  # SQL: CREATE TABLE license_sparks ( `account_id` UUID, `environment_id` Nullable(UUID), `count` UInt64 DEFAULT 0, `created_date` Date, `created_at` DateTime64(3) ) ENGINE = MergeTree PARTITION BY toYYYYMM(created_date) ORDER BY (account_id, created_date, environment_id) SETTINGS allow_nullable_key = 1, index_granularity = 8192
  create_table "license_sparks", id: false, options: "MergeTree PARTITION BY toYYYYMM(created_date) ORDER BY (account_id, created_date, environment_id) SETTINGS allow_nullable_key = 1, index_granularity = 8192", force: :cascade do |t|
    t.uuid "account_id", null: false
    t.uuid "environment_id"
    t.integer "count", limit: 8, default: 0, null: false
    t.date "created_date", null: false
    t.datetime "created_at", precision: 3, null: false
  end

  # TABLE: machine_sparks
  # SQL: CREATE TABLE machine_sparks ( `account_id` UUID, `environment_id` Nullable(UUID), `count` UInt64 DEFAULT 0, `created_date` Date, `created_at` DateTime64(3) ) ENGINE = MergeTree PARTITION BY toYYYYMM(created_date) ORDER BY (account_id, created_date, environment_id) SETTINGS allow_nullable_key = 1, index_granularity = 8192
  create_table "machine_sparks", id: false, options: "MergeTree PARTITION BY toYYYYMM(created_date) ORDER BY (account_id, created_date, environment_id) SETTINGS allow_nullable_key = 1, index_granularity = 8192", force: :cascade do |t|
    t.uuid "account_id", null: false
    t.uuid "environment_id"
    t.integer "count", limit: 8, default: 0, null: false
    t.date "created_date", null: false
    t.datetime "created_at", precision: 3, null: false
  end

  # TABLE: request_logs
  # SQL: CREATE TABLE request_logs ( `id` UUID, `account_id` UUID, `environment_id` Nullable(UUID), `created_at` DateTime64(3), `updated_at` DateTime64(3), `created_date` Date, `method` LowCardinality(Nullable(String)), `status` LowCardinality(Nullable(String)), `url` Nullable(String), `ip` Nullable(String) TTL created_at + toIntervalDay(30), `user_agent` Nullable(String) TTL created_at + toIntervalDay(30), `requestor_type` LowCardinality(Nullable(String)), `requestor_id` Nullable(UUID), `resource_type` LowCardinality(Nullable(String)), `resource_id` Nullable(UUID), `request_body` Nullable(String) CODEC(ZSTD(1)) TTL created_at + toIntervalDay(30), `request_headers` Nullable(JSON) TTL created_at + toIntervalDay(30), `response_body` Nullable(String) CODEC(ZSTD(1)) TTL created_at + toIntervalDay(30), `response_headers` Nullable(JSON) TTL created_at + toIntervalDay(30), `response_signature` Nullable(String) CODEC(ZSTD(1)) TTL created_at + toIntervalDay(30), `queue_time` Nullable(Float32), `run_time` Nullable(Float32), `is_deleted` UInt8 DEFAULT 0, `ver` DateTime64(3) DEFAULT now(), `ttl` UInt32 DEFAULT 2592000, INDEX idx_status status TYPE set(100) GRANULARITY 4, INDEX idx_method method TYPE set(20) GRANULARITY 4, INDEX idx_requestor (requestor_type, requestor_id) TYPE bloom_filter GRANULARITY 4, INDEX idx_resource (resource_type, resource_id) TYPE bloom_filter GRANULARITY 4, INDEX idx_ip ip TYPE bloom_filter GRANULARITY 4, INDEX idx_environment environment_id TYPE bloom_filter GRANULARITY 4, INDEX idx_id id TYPE bloom_filter GRANULARITY 4 ) ENGINE = ReplacingMergeTree(ver, is_deleted) PARTITION BY toYYYYMMDD(created_date) ORDER BY (account_id, created_date, id) TTL created_at + toIntervalSecond(ttl) SETTINGS index_granularity = 8192
  create_table "request_logs", id: :uuid, options: "ReplacingMergeTree(ver, is_deleted) PARTITION BY toYYYYMMDD(created_date) ORDER BY (account_id, created_date, id) TTL created_at + toIntervalSecond(ttl) SETTINGS index_granularity = 8192", force: :cascade do |t|
    t.uuid "id", null: false
    t.uuid "account_id", null: false
    t.uuid "environment_id"
    t.datetime "created_at", precision: 3, null: false
    t.datetime "updated_at", precision: 3, null: false
    t.date "created_date", null: false
    t.string "method", low_cardinality: true
    t.string "status", low_cardinality: true
    t.string "url"
    t.string "ip", ttl: "created_at + toIntervalDay(30)"
    t.string "user_agent", ttl: "created_at + toIntervalDay(30)"
    t.string "requestor_type", low_cardinality: true
    t.uuid "requestor_id"
    t.string "resource_type", low_cardinality: true
    t.uuid "resource_id"
    t.string "request_body", codec: "ZSTD(1)", ttl: "created_at + toIntervalDay(30)"
    t.json "request_headers", ttl: "created_at + toIntervalDay(30)"
    t.string "response_body", codec: "ZSTD(1)", ttl: "created_at + toIntervalDay(30)"
    t.json "response_headers", ttl: "created_at + toIntervalDay(30)"
    t.string "response_signature", codec: "ZSTD(1)", ttl: "created_at + toIntervalDay(30)"
    t.float "queue_time"
    t.float "run_time"
    t.integer "is_deleted", limit: 1, default: 0, null: false
    t.datetime "ver", precision: 3, default: -> { "now()" }, null: false
    t.integer "ttl", default: 2592000, null: false

    t.index "status", name: "idx_status", type: "set(100)", granularity: 4
    t.index "method", name: "idx_method", type: "set(20)", granularity: 4
    t.index "(requestor_type, requestor_id)", name: "idx_requestor", type: "bloom_filter", granularity: 4
    t.index "(resource_type, resource_id)", name: "idx_resource", type: "bloom_filter", granularity: 4
    t.index "ip", name: "idx_ip", type: "bloom_filter", granularity: 4
    t.index "environment_id", name: "idx_environment", type: "bloom_filter", granularity: 4
    t.index "id", name: "idx_id", type: "bloom_filter", granularity: 4
  end

  # TABLE: user_sparks
  # SQL: CREATE TABLE user_sparks ( `account_id` UUID, `environment_id` Nullable(UUID), `count` UInt64 DEFAULT 0, `created_date` Date, `created_at` DateTime64(3) ) ENGINE = MergeTree PARTITION BY toYYYYMM(created_date) ORDER BY (account_id, created_date, environment_id) SETTINGS allow_nullable_key = 1, index_granularity = 8192
  create_table "user_sparks", id: false, options: "MergeTree PARTITION BY toYYYYMM(created_date) ORDER BY (account_id, created_date, environment_id) SETTINGS allow_nullable_key = 1, index_granularity = 8192", force: :cascade do |t|
    t.uuid "account_id", null: false
    t.uuid "environment_id"
    t.integer "count", limit: 8, default: 0, null: false
    t.date "created_date", null: false
    t.datetime "created_at", precision: 3, null: false
  end

end
