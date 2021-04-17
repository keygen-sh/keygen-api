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

ActiveRecord::Schema.define(version: 2021_04_17_125404) do

  # These are extensions that must be enabled in order to support this database
  enable_extension "btree_gin"
  enable_extension "pg_stat_statements"
  enable_extension "plpgsql"
  enable_extension "uuid-ossp"

  create_table "accounts", id: :uuid, default: -> { "uuid_generate_v4()" }, force: :cascade do |t|
    t.string "name"
    t.string "slug"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.uuid "plan_id"
    t.boolean "protected", default: false
    t.text "public_key"
    t.text "private_key"
    t.text "secret_key"
    t.datetime "last_low_activity_lifeline_sent_at"
    t.datetime "last_trial_will_end_sent_at"
    t.datetime "last_license_limit_exceeded_sent_at"
    t.datetime "last_request_limit_exceeded_sent_at"
    t.index ["created_at"], name: "index_accounts_on_created_at", order: :desc
    t.index ["id", "created_at"], name: "index_accounts_on_id_and_created_at", unique: true
    t.index ["plan_id", "created_at"], name: "index_accounts_on_plan_id_and_created_at"
    t.index ["slug", "created_at"], name: "index_accounts_on_slug_and_created_at", unique: true
    t.index ["slug"], name: "index_accounts_on_slug", unique: true
  end

  create_table "billings", id: :uuid, default: -> { "uuid_generate_v4()" }, force: :cascade do |t|
    t.string "customer_id"
    t.string "subscription_status"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "subscription_id"
    t.datetime "subscription_period_start"
    t.datetime "subscription_period_end"
    t.datetime "card_expiry"
    t.string "card_brand"
    t.string "card_last4"
    t.string "state"
    t.uuid "account_id"
    t.index ["account_id", "created_at"], name: "index_billings_on_account_id_and_created_at"
    t.index ["created_at"], name: "index_billings_on_created_at", order: :desc
    t.index ["customer_id", "created_at"], name: "index_billings_on_customer_id_and_created_at"
    t.index ["id", "created_at"], name: "index_billings_on_id_and_created_at", unique: true
    t.index ["subscription_id", "created_at"], name: "index_billings_on_subscription_id_and_created_at"
  end

  create_table "entitlements", id: :uuid, default: -> { "uuid_generate_v4()" }, force: :cascade do |t|
    t.uuid "account_id", null: false
    t.string "name", null: false
    t.string "code", null: false
    t.jsonb "metadata"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.index ["account_id", "code"], name: "index_entitlements_on_account_id_and_code", unique: true
    t.index ["code"], name: "index_entitlements_on_code"
  end

  create_table "event_types", id: :uuid, default: -> { "uuid_generate_v4()" }, force: :cascade do |t|
    t.string "event"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["event"], name: "index_event_types_on_event", unique: true
  end

  create_table "keys", id: :uuid, default: -> { "uuid_generate_v4()" }, force: :cascade do |t|
    t.string "key"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.uuid "policy_id"
    t.uuid "account_id"
    t.index "to_tsvector('simple'::regconfig, COALESCE((id)::text, ''::text))", name: "keys_tsv_id_idx", using: :gist
    t.index "to_tsvector('simple'::regconfig, \"left\"(COALESCE((key)::text, ''::text), 128))", name: "keys_tsv_key_idx", using: :gist
    t.index ["account_id", "created_at"], name: "index_keys_on_account_id_and_created_at"
    t.index ["created_at"], name: "index_keys_on_created_at", order: :desc
    t.index ["id", "created_at", "account_id"], name: "index_keys_on_id_and_created_at_and_account_id", unique: true
    t.index ["policy_id", "created_at"], name: "index_keys_on_policy_id_and_created_at"
  end

  create_table "license_entitlements", id: :uuid, default: -> { "uuid_generate_v4()" }, force: :cascade do |t|
    t.uuid "account_id", null: false
    t.uuid "license_id", null: false
    t.uuid "entitlement_id", null: false
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.index ["account_id", "license_id", "entitlement_id"], name: "license_entitlements_acct_lic_ent_ids_idx", unique: true
    t.index ["entitlement_id"], name: "index_license_entitlements_on_entitlement_id"
    t.index ["license_id"], name: "index_license_entitlements_on_license_id"
  end

  create_table "licenses", id: :uuid, default: -> { "uuid_generate_v4()" }, force: :cascade do |t|
    t.string "key", null: false
    t.datetime "expiry"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.jsonb "metadata"
    t.uuid "user_id"
    t.uuid "policy_id"
    t.uuid "account_id"
    t.boolean "suspended", default: false
    t.datetime "last_check_in_at"
    t.datetime "last_expiration_event_sent_at"
    t.datetime "last_check_in_event_sent_at"
    t.datetime "last_expiring_soon_event_sent_at"
    t.datetime "last_check_in_soon_event_sent_at"
    t.integer "uses", default: 0
    t.boolean "protected"
    t.string "name"
    t.integer "machines_count", default: 0
    t.datetime "last_validated_at"
    t.integer "machines_core_count"
    t.index "account_id, md5((key)::text)", name: "licenses_account_id_key_unique_idx", unique: true
    t.index "to_tsvector('simple'::regconfig, COALESCE((id)::text, ''::text))", name: "licenses_tsv_id_idx", using: :gist
    t.index "to_tsvector('simple'::regconfig, COALESCE((metadata)::text, ''::text))", name: "licenses_tsv_metadata_idx", using: :gist
    t.index "to_tsvector('simple'::regconfig, COALESCE((name)::text, ''::text))", name: "licenses_tsv_name_idx", using: :gin
    t.index ["account_id", "created_at"], name: "index_licenses_on_account_id_and_created_at"
    t.index ["created_at"], name: "index_licenses_on_created_at", order: :desc
    t.index ["id", "created_at", "account_id"], name: "index_licenses_on_id_and_created_at_and_account_id", unique: true
    t.index ["key"], name: "licenses_hash_key_idx", using: :hash
    t.index ["policy_id", "created_at"], name: "index_licenses_on_policy_id_and_created_at"
    t.index ["user_id", "created_at"], name: "index_licenses_on_user_id_and_created_at"
  end

  create_table "machines", id: :uuid, default: -> { "uuid_generate_v4()" }, force: :cascade do |t|
    t.string "fingerprint"
    t.string "ip"
    t.string "hostname"
    t.string "platform"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "name"
    t.jsonb "metadata"
    t.uuid "account_id"
    t.uuid "license_id"
    t.datetime "last_heartbeat_at"
    t.integer "cores"
    t.index "license_id, md5((fingerprint)::text)", name: "machines_license_id_fingerprint_unique_idx", unique: true
    t.index "to_tsvector('simple'::regconfig, COALESCE((id)::text, ''::text))", name: "machines_tsv_id_idx", using: :gist
    t.index "to_tsvector('simple'::regconfig, COALESCE((metadata)::text, ''::text))", name: "machines_tsv_metadata_idx", using: :gist
    t.index "to_tsvector('simple'::regconfig, COALESCE((name)::text, ''::text))", name: "machines_tsv_name_idx", using: :gist
    t.index ["account_id", "created_at"], name: "index_machines_on_account_id_and_created_at"
    t.index ["created_at"], name: "index_machines_on_created_at", order: :desc
    t.index ["fingerprint"], name: "index_machines_on_fingerprint", using: :gin
    t.index ["fingerprint"], name: "machines_hash_fingerprint_idx", using: :hash
    t.index ["id", "created_at", "account_id"], name: "index_machines_on_id_and_created_at_and_account_id", unique: true
    t.index ["license_id", "created_at"], name: "index_machines_on_license_id_and_created_at"
  end

  create_table "metrics", id: :uuid, default: -> { "uuid_generate_v4()" }, force: :cascade do |t|
    t.uuid "account_id"
    t.jsonb "data"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.uuid "event_type_id", null: false
    t.index ["account_id", "created_at", "event_type_id"], name: "metrics_account_created_event_type_idx", order: { created_at: :desc }, where: "(event_type_id <> ALL (ARRAY['b4d4a9ff-1a63-4d5f-b95f-617788fb50dc'::uuid, 'a0a302c6-2872-4983-b815-391a5022d469'::uuid, '918f5d37-7369-454e-a5e5-9385a46f184a'::uuid, 'ac3e4f4b-712c-4cce-aa33-81788d4c4fbf'::uuid, '7b14b995-2a2b-4f1f-9628-16a3bc9e8d76'::uuid, 'cbd8b04c-1fd7-41b9-b11d-74c9deb60c77'::uuid, 'b4e5d6f2-25ff-46fb-9e1e-91ead72c0ccc'::uuid, 'ebb19f81-ca0f-4af4-bdbe-7476b22778ba'::uuid, '6f75f2c4-6451-405a-a389-fa029137f6f0'::uuid]))"
    t.index ["account_id", "created_at", "event_type_id"], name: "metrics_high_vol_account_created_event_type_idx", order: { created_at: :desc }, where: "(event_type_id = ANY (ARRAY['b4d4a9ff-1a63-4d5f-b95f-617788fb50dc'::uuid, 'a0a302c6-2872-4983-b815-391a5022d469'::uuid, '918f5d37-7369-454e-a5e5-9385a46f184a'::uuid, 'ac3e4f4b-712c-4cce-aa33-81788d4c4fbf'::uuid, '7b14b995-2a2b-4f1f-9628-16a3bc9e8d76'::uuid, 'cbd8b04c-1fd7-41b9-b11d-74c9deb60c77'::uuid, 'b4e5d6f2-25ff-46fb-9e1e-91ead72c0ccc'::uuid, 'ebb19f81-ca0f-4af4-bdbe-7476b22778ba'::uuid]))"
    t.index ["account_id"], name: "index_metrics_on_account_id"
    t.index ["created_at"], name: "index_metrics_on_created_at", order: :desc
    t.index ["event_type_id"], name: "index_metrics_on_event_type_id"
  end

  create_table "plans", id: :uuid, default: -> { "uuid_generate_v4()" }, force: :cascade do |t|
    t.string "name"
    t.integer "price"
    t.integer "max_users"
    t.integer "max_policies"
    t.integer "max_licenses"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "max_products"
    t.string "plan_id"
    t.boolean "private", default: false
    t.integer "trial_duration"
    t.integer "max_reqs"
    t.integer "max_admins"
    t.string "interval"
    t.index ["created_at"], name: "index_plans_on_created_at", order: :desc
    t.index ["id", "created_at"], name: "index_plans_on_id_and_created_at", unique: true
    t.index ["plan_id", "created_at"], name: "index_plans_on_plan_id_and_created_at"
  end

  create_table "policies", id: :uuid, default: -> { "uuid_generate_v4()" }, force: :cascade do |t|
    t.string "name"
    t.integer "duration"
    t.boolean "strict", default: false
    t.boolean "floating", default: false
    t.boolean "use_pool", default: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "lock_version", default: 0, null: false
    t.integer "max_machines"
    t.boolean "encrypted", default: false
    t.boolean "protected"
    t.jsonb "metadata"
    t.uuid "product_id"
    t.uuid "account_id"
    t.string "check_in_interval"
    t.integer "check_in_interval_count"
    t.boolean "require_check_in", default: false
    t.boolean "require_product_scope", default: false
    t.boolean "require_policy_scope", default: false
    t.boolean "require_machine_scope", default: false
    t.boolean "require_fingerprint_scope", default: false
    t.boolean "concurrent", default: true
    t.integer "max_uses"
    t.string "scheme"
    t.integer "heartbeat_duration"
    t.string "fingerprint_uniqueness_strategy"
    t.string "fingerprint_matching_strategy"
    t.integer "max_cores"
    t.index "to_tsvector('simple'::regconfig, COALESCE((id)::text, ''::text))", name: "policies_tsv_id_idx", using: :gist
    t.index "to_tsvector('simple'::regconfig, COALESCE((metadata)::text, ''::text))", name: "policies_tsv_metadata_idx", using: :gist
    t.index "to_tsvector('simple'::regconfig, COALESCE((name)::text, ''::text))", name: "policies_tsv_name_idx", using: :gist
    t.index ["account_id", "created_at"], name: "index_policies_on_account_id_and_created_at"
    t.index ["created_at"], name: "index_policies_on_created_at", order: :desc
    t.index ["id", "created_at", "account_id"], name: "index_policies_on_id_and_created_at_and_account_id", unique: true
    t.index ["product_id", "created_at"], name: "index_policies_on_product_id_and_created_at"
  end

  create_table "policy_entitlements", id: :uuid, default: -> { "uuid_generate_v4()" }, force: :cascade do |t|
    t.uuid "account_id", null: false
    t.uuid "policy_id", null: false
    t.uuid "entitlement_id", null: false
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.index ["account_id", "policy_id", "entitlement_id"], name: "policy_entitlements_acct_lic_ent_ids_idx", unique: true
    t.index ["entitlement_id"], name: "index_policy_entitlements_on_entitlement_id"
    t.index ["policy_id"], name: "index_policy_entitlements_on_policy_id"
  end

  create_table "products", id: :uuid, default: -> { "uuid_generate_v4()" }, force: :cascade do |t|
    t.string "name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.jsonb "platforms"
    t.jsonb "metadata"
    t.uuid "account_id"
    t.string "url"
    t.index "to_tsvector('simple'::regconfig, COALESCE((id)::text, ''::text))", name: "products_tsv_id_idx", using: :gist
    t.index "to_tsvector('simple'::regconfig, COALESCE((metadata)::text, ''::text))", name: "products_tsv_metadata_idx", using: :gist
    t.index "to_tsvector('simple'::regconfig, COALESCE((name)::text, ''::text))", name: "products_tsv_name_idx", using: :gist
    t.index ["account_id", "created_at"], name: "index_products_on_account_id_and_created_at"
    t.index ["created_at"], name: "index_products_on_created_at", order: :desc
    t.index ["id", "created_at", "account_id"], name: "index_products_on_id_and_created_at_and_account_id", unique: true
  end

  create_table "receipts", id: :uuid, default: -> { "uuid_generate_v4()" }, force: :cascade do |t|
    t.string "invoice_id"
    t.integer "amount"
    t.boolean "paid"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.uuid "billing_id"
    t.index ["billing_id", "created_at"], name: "index_receipts_on_billing_id_and_created_at"
    t.index ["created_at"], name: "index_receipts_on_created_at", order: :desc
    t.index ["id", "created_at"], name: "index_receipts_on_id_and_created_at", unique: true
  end

  create_table "request_logs", id: :uuid, default: -> { "uuid_generate_v4()" }, force: :cascade do |t|
    t.uuid "account_id"
    t.string "request_id"
    t.string "url"
    t.string "method"
    t.string "ip"
    t.string "user_agent"
    t.string "status"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "requestor_type"
    t.uuid "requestor_id"
    t.text "request_body"
    t.text "response_body"
    t.text "response_signature"
    t.string "resource_type"
    t.uuid "resource_id"
    t.index "to_tsvector('simple'::regconfig, (ip)::text)", name: "request_logs_tsv_ip_idx", using: :gin
    t.index "to_tsvector('simple'::regconfig, (request_id)::text)", name: "request_logs_tsv_request_id_idx", using: :gin
    t.index "to_tsvector('simple'::regconfig, (requestor_id)::text)", name: "request_logs_tsv_requestor_id_idx", using: :gin
    t.index "to_tsvector('simple'::regconfig, (resource_id)::text)", name: "request_logs_tsv_resource_id_idx", using: :gin
    t.index ["request_id", "created_at"], name: "request_logs_request_id_created_idx", unique: true
    t.index ["requestor_id", "requestor_type", "created_at"], name: "request_logs_requestor_idx"
    t.index ["resource_id", "resource_type", "created_at"], name: "request_logs_resource_idx"
    t.index ["url"], name: "index_request_logs_on_url", using: :gin
  end

  create_table "roles", id: :uuid, default: -> { "uuid_generate_v4()" }, force: :cascade do |t|
    t.string "name"
    t.string "resource_type"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.uuid "resource_id"
    t.index ["created_at"], name: "index_roles_on_created_at", order: :desc
    t.index ["id", "created_at"], name: "index_roles_on_id_and_created_at", unique: true
    t.index ["name", "created_at"], name: "index_roles_on_name_and_created_at"
    t.index ["resource_id", "resource_type", "created_at"], name: "index_roles_on_resource_id_and_resource_type_and_created_at"
  end

  create_table "second_factors", id: :uuid, default: -> { "uuid_generate_v4()" }, force: :cascade do |t|
    t.uuid "account_id", null: false
    t.uuid "user_id", null: false
    t.text "secret", null: false
    t.boolean "enabled", default: false, null: false
    t.datetime "last_verified_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["account_id", "created_at"], name: "index_second_factors_on_account_id_and_created_at"
    t.index ["id", "created_at"], name: "index_second_factors_on_id_and_created_at", unique: true
    t.index ["secret"], name: "index_second_factors_on_secret", unique: true
    t.index ["user_id"], name: "index_second_factors_on_user_id", unique: true
  end

  create_table "tokens", id: :uuid, default: -> { "uuid_generate_v4()" }, force: :cascade do |t|
    t.string "digest"
    t.string "bearer_type"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.datetime "expiry"
    t.uuid "bearer_id"
    t.uuid "account_id"
    t.integer "max_activations"
    t.integer "max_deactivations"
    t.integer "activations", default: 0
    t.integer "deactivations", default: 0
    t.index ["account_id", "created_at"], name: "index_tokens_on_account_id_and_created_at"
    t.index ["bearer_id", "bearer_type", "created_at"], name: "index_tokens_on_bearer_id_and_bearer_type_and_created_at"
    t.index ["created_at"], name: "index_tokens_on_created_at", order: :desc
    t.index ["digest"], name: "index_tokens_on_digest", unique: true
    t.index ["id", "created_at", "account_id"], name: "index_tokens_on_id_and_created_at_and_account_id", unique: true
  end

  create_table "users", id: :uuid, default: -> { "uuid_generate_v4()" }, force: :cascade do |t|
    t.string "email"
    t.string "password_digest"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "password_reset_token"
    t.datetime "password_reset_sent_at"
    t.jsonb "metadata"
    t.uuid "account_id"
    t.string "first_name"
    t.string "last_name"
    t.index "to_tsvector('simple'::regconfig, COALESCE((first_name)::text, ''::text))", name: "users_tsv_first_name_idx", using: :gist
    t.index "to_tsvector('simple'::regconfig, COALESCE((id)::text, ''::text))", name: "users_tsv_id_idx", using: :gist
    t.index "to_tsvector('simple'::regconfig, COALESCE((last_name)::text, ''::text))", name: "users_tsv_last_name_idx", using: :gist
    t.index "to_tsvector('simple'::regconfig, COALESCE((metadata)::text, ''::text))", name: "users_tsv_metadata_idx", using: :gist
    t.index ["account_id", "created_at"], name: "index_users_on_account_id_and_created_at"
    t.index ["created_at"], name: "index_users_on_created_at", order: :desc
    t.index ["email", "account_id"], name: "index_users_on_email_and_account_id", unique: true
    t.index ["email"], name: "index_users_on_email", using: :gin
    t.index ["id", "created_at", "account_id"], name: "index_users_on_id_and_created_at_and_account_id", unique: true
  end

  create_table "webhook_endpoints", id: :uuid, default: -> { "uuid_generate_v4()" }, force: :cascade do |t|
    t.string "url"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.uuid "account_id"
    t.jsonb "subscriptions", default: ["*"]
    t.index ["account_id", "created_at"], name: "index_webhook_endpoints_on_account_id_and_created_at"
    t.index ["created_at"], name: "index_webhook_endpoints_on_created_at", order: :desc
    t.index ["id", "created_at", "account_id"], name: "index_webhook_endpoints_on_id_and_created_at_and_account_id", unique: true
  end

  create_table "webhook_events", id: :uuid, default: -> { "uuid_generate_v4()" }, force: :cascade do |t|
    t.text "payload"
    t.string "jid"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "endpoint"
    t.uuid "account_id"
    t.string "idempotency_token"
    t.integer "last_response_code"
    t.text "last_response_body"
    t.uuid "event_type_id", null: false
    t.index ["account_id", "created_at"], name: "index_webhook_events_on_account_id_and_created_at", order: { created_at: :desc }
    t.index ["event_type_id"], name: "index_webhook_events_on_event_type_id"
    t.index ["id", "created_at", "account_id"], name: "index_webhook_events_on_id_and_created_at_and_account_id", unique: true
    t.index ["idempotency_token"], name: "index_webhook_events_on_idempotency_token"
    t.index ["jid", "created_at", "account_id"], name: "index_webhook_events_on_jid_and_created_at_and_account_id"
  end

end
