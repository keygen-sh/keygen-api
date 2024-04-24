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

ActiveRecord::Schema[7.1].define(version: 2024_04_24_041244) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "btree_gin"
  enable_extension "pg_stat_statements"
  enable_extension "plpgsql"
  enable_extension "uuid-ossp"

  create_table "accounts", id: :uuid, default: -> { "uuid_generate_v4()" }, force: :cascade do |t|
    t.string "name"
    t.string "slug"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.uuid "plan_id"
    t.boolean "protected", default: false
    t.text "public_key"
    t.text "private_key"
    t.text "secret_key"
    t.datetime "last_low_activity_lifeline_sent_at", precision: nil
    t.datetime "last_trial_will_end_sent_at", precision: nil
    t.datetime "last_license_limit_exceeded_sent_at", precision: nil
    t.datetime "last_request_limit_exceeded_sent_at", precision: nil
    t.datetime "last_prompt_for_review_sent_at", precision: nil
    t.text "ed25519_private_key"
    t.text "ed25519_public_key"
    t.string "domain"
    t.string "subdomain"
    t.string "api_version"
    t.string "cname"
    t.string "backend"
    t.index ["cname"], name: "index_accounts_on_cname", unique: true
    t.index ["created_at"], name: "index_accounts_on_created_at", order: :desc
    t.index ["domain"], name: "index_accounts_on_domain", unique: true
    t.index ["id", "created_at"], name: "index_accounts_on_id_and_created_at", unique: true
    t.index ["plan_id", "created_at"], name: "index_accounts_on_plan_id_and_created_at"
    t.index ["slug", "created_at"], name: "index_accounts_on_slug_and_created_at", unique: true
    t.index ["slug"], name: "index_accounts_on_slug", unique: true
    t.index ["subdomain"], name: "index_accounts_on_subdomain", unique: true
  end

  create_table "billings", id: :uuid, default: -> { "uuid_generate_v4()" }, force: :cascade do |t|
    t.string "customer_id"
    t.string "subscription_status"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.string "subscription_id"
    t.datetime "subscription_period_start", precision: nil
    t.datetime "subscription_period_end", precision: nil
    t.datetime "card_expiry", precision: nil
    t.string "card_brand"
    t.string "card_last4"
    t.string "state"
    t.uuid "account_id"
    t.string "referral_id"
    t.datetime "card_added_at", precision: nil
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
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.uuid "environment_id"
    t.index ["account_id", "code"], name: "index_entitlements_on_account_id_and_code", unique: true
    t.index ["code"], name: "index_entitlements_on_code"
    t.index ["environment_id"], name: "index_entitlements_on_environment_id"
  end

  create_table "environments", id: :uuid, default: -> { "uuid_generate_v4()" }, force: :cascade do |t|
    t.uuid "account_id", null: false
    t.string "name", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "code", null: false
    t.string "isolation_strategy", null: false
    t.index ["account_id", "code"], name: "index_environments_on_account_id_and_code", unique: true
    t.index ["account_id", "created_at"], name: "index_environments_on_account_id_and_created_at", order: { created_at: :desc }
    t.index ["code"], name: "index_environments_on_code"
  end

  create_table "event_logs", id: :uuid, default: -> { "uuid_generate_v4()" }, force: :cascade do |t|
    t.uuid "account_id", null: false
    t.uuid "event_type_id", null: false
    t.string "resource_type", null: false
    t.uuid "resource_id", null: false
    t.string "whodunnit_type"
    t.uuid "whodunnit_id"
    t.uuid "request_log_id"
    t.string "idempotency_key"
    t.jsonb "metadata"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.uuid "environment_id"
    t.date "created_date"
    t.index ["account_id", "created_at"], name: "index_event_logs_on_account_id_and_created_at", order: { created_at: :desc }
    t.index ["account_id", "created_date"], name: "index_event_logs_on_account_id_and_created_date", order: { created_date: :desc }
    t.index ["environment_id"], name: "index_event_logs_on_environment_id"
    t.index ["event_type_id"], name: "index_event_logs_on_event_type_id"
    t.index ["idempotency_key"], name: "index_event_logs_on_idempotency_key", unique: true
    t.index ["request_log_id"], name: "index_event_logs_on_request_log_id"
    t.index ["resource_type", "resource_id", "created_at"], name: "event_logs_resource_crt_idx", order: { created_at: :desc }
    t.index ["whodunnit_type", "whodunnit_id", "created_at"], name: "event_logs_whodunnit_crt_idx", order: { created_at: :desc }
  end

  create_table "event_types", id: :uuid, default: -> { "uuid_generate_v4()" }, force: :cascade do |t|
    t.string "event"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.index ["event"], name: "index_event_types_on_event", unique: true
  end

  create_table "group_owners", id: :uuid, default: -> { "uuid_generate_v4()" }, force: :cascade do |t|
    t.uuid "account_id", null: false
    t.uuid "group_id", null: false
    t.uuid "user_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.uuid "environment_id"
    t.index ["account_id"], name: "index_group_owners_on_account_id"
    t.index ["environment_id"], name: "index_group_owners_on_environment_id"
    t.index ["group_id", "user_id"], name: "index_group_owners_on_group_id_and_user_id", unique: true
    t.index ["group_id"], name: "index_group_owners_on_group_id"
    t.index ["user_id"], name: "index_group_owners_on_user_id"
  end

  create_table "group_permissions", id: :uuid, default: -> { "uuid_generate_v4()" }, force: :cascade do |t|
    t.uuid "permission_id", null: false
    t.uuid "group_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["group_id", "permission_id"], name: "index_group_permissions_on_group_id_and_permission_id", unique: true
    t.index ["permission_id"], name: "index_group_permissions_on_permission_id"
  end

  create_table "groups", id: :uuid, default: -> { "uuid_generate_v4()" }, force: :cascade do |t|
    t.uuid "account_id", null: false
    t.string "name"
    t.integer "max_users"
    t.integer "max_licenses"
    t.integer "max_machines"
    t.jsonb "metadata"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.uuid "environment_id"
    t.index ["account_id"], name: "index_groups_on_account_id"
    t.index ["environment_id"], name: "index_groups_on_environment_id"
  end

  create_table "keys", id: :uuid, default: -> { "uuid_generate_v4()" }, force: :cascade do |t|
    t.string "key"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.uuid "policy_id"
    t.uuid "account_id"
    t.uuid "environment_id"
    t.index "to_tsvector('simple'::regconfig, COALESCE((id)::text, ''::text))", name: "keys_tsv_id_idx", using: :gist
    t.index "to_tsvector('simple'::regconfig, \"left\"(COALESCE((key)::text, ''::text), 128))", name: "keys_tsv_key_idx", using: :gist
    t.index ["account_id", "created_at"], name: "index_keys_on_account_id_and_created_at"
    t.index ["account_id", "key"], name: "index_keys_on_account_id_and_key", unique: true
    t.index ["created_at"], name: "index_keys_on_created_at", order: :desc
    t.index ["environment_id"], name: "index_keys_on_environment_id"
    t.index ["id", "created_at", "account_id"], name: "index_keys_on_id_and_created_at_and_account_id", unique: true
    t.index ["policy_id", "created_at"], name: "index_keys_on_policy_id_and_created_at"
  end

  create_table "license_entitlements", id: :uuid, default: -> { "uuid_generate_v4()" }, force: :cascade do |t|
    t.uuid "account_id", null: false
    t.uuid "license_id", null: false
    t.uuid "entitlement_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.uuid "environment_id"
    t.index ["account_id", "license_id", "entitlement_id"], name: "license_entitlements_acct_lic_ent_ids_idx", unique: true
    t.index ["entitlement_id"], name: "index_license_entitlements_on_entitlement_id"
    t.index ["environment_id"], name: "index_license_entitlements_on_environment_id"
    t.index ["license_id"], name: "index_license_entitlements_on_license_id"
  end

  create_table "licenses", id: :uuid, default: -> { "uuid_generate_v4()" }, force: :cascade do |t|
    t.string "key", null: false
    t.datetime "expiry", precision: nil
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.jsonb "metadata"
    t.uuid "user_id"
    t.uuid "policy_id", null: false
    t.uuid "account_id", null: false
    t.boolean "suspended", default: false
    t.datetime "last_check_in_at", precision: nil
    t.datetime "last_expiration_event_sent_at", precision: nil
    t.datetime "last_check_in_event_sent_at", precision: nil
    t.datetime "last_expiring_soon_event_sent_at", precision: nil
    t.datetime "last_check_in_soon_event_sent_at", precision: nil
    t.integer "uses", default: 0
    t.boolean "protected"
    t.string "name"
    t.integer "machines_count", default: 0
    t.datetime "last_validated_at", precision: nil
    t.integer "machines_core_count"
    t.integer "max_machines_override"
    t.integer "max_cores_override"
    t.integer "max_uses_override"
    t.uuid "group_id"
    t.integer "max_processes_override"
    t.datetime "last_check_out_at", precision: nil
    t.uuid "environment_id"
    t.string "last_validated_checksum"
    t.string "last_validated_version"
    t.uuid "product_id", null: false
    t.index "account_id, md5((key)::text)", name: "licenses_account_id_key_unique_idx", unique: true
    t.index "to_tsvector('simple'::regconfig, COALESCE((id)::text, ''::text))", name: "licenses_tsv_id_idx", using: :gist
    t.index "to_tsvector('simple'::regconfig, COALESCE((metadata)::text, ''::text))", name: "licenses_tsv_metadata_idx", using: :gist
    t.index "to_tsvector('simple'::regconfig, COALESCE((name)::text, ''::text))", name: "licenses_tsv_name_idx", using: :gist
    t.index ["account_id", "created_at"], name: "index_licenses_on_account_id_and_created_at"
    t.index ["created_at"], name: "index_licenses_on_created_at", order: :desc
    t.index ["environment_id"], name: "index_licenses_on_environment_id"
    t.index ["group_id"], name: "index_licenses_on_group_id"
    t.index ["id", "created_at", "account_id"], name: "index_licenses_on_id_and_created_at_and_account_id", unique: true
    t.index ["key"], name: "licenses_hash_key_idx", using: :hash
    t.index ["last_validated_at"], name: "index_licenses_on_last_validated_at"
    t.index ["policy_id", "created_at"], name: "index_licenses_on_policy_id_and_created_at"
    t.index ["product_id"], name: "index_licenses_on_product_id"
    t.index ["user_id", "created_at"], name: "index_licenses_on_user_id_and_created_at"
  end

  create_table "machine_components", id: :uuid, default: -> { "uuid_generate_v4()" }, force: :cascade do |t|
    t.uuid "account_id", null: false
    t.uuid "machine_id", null: false
    t.uuid "environment_id"
    t.string "fingerprint", null: false
    t.string "name", null: false
    t.jsonb "metadata"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["account_id", "created_at"], name: "index_machine_components_on_account_id_and_created_at", order: { created_at: :desc }
    t.index ["environment_id"], name: "index_machine_components_on_environment_id"
    t.index ["fingerprint"], name: "index_machine_components_on_fingerprint"
    t.index ["machine_id", "fingerprint"], name: "index_machine_components_on_machine_id_and_fingerprint", unique: true
  end

  create_table "machine_processes", id: :uuid, default: -> { "uuid_generate_v4()" }, force: :cascade do |t|
    t.uuid "account_id", null: false
    t.uuid "machine_id", null: false
    t.string "pid", null: false
    t.datetime "last_heartbeat_at", null: false
    t.datetime "last_death_event_sent_at"
    t.jsonb "metadata"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.uuid "environment_id"
    t.string "heartbeat_jid"
    t.index "machine_id, md5((pid)::text)", name: "index_machine_processes_on_machine_id_md5_pid", unique: true
    t.index ["account_id"], name: "index_machine_processes_on_account_id"
    t.index ["environment_id"], name: "index_machine_processes_on_environment_id"
    t.index ["heartbeat_jid"], name: "index_machine_processes_on_heartbeat_jid"
    t.index ["last_heartbeat_at"], name: "index_machine_processes_on_last_heartbeat_at"
    t.index ["machine_id"], name: "index_machine_processes_on_machine_id"
  end

  create_table "machines", id: :uuid, default: -> { "uuid_generate_v4()" }, force: :cascade do |t|
    t.string "fingerprint"
    t.string "ip"
    t.string "hostname"
    t.string "platform"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.string "name"
    t.jsonb "metadata"
    t.uuid "account_id", null: false
    t.uuid "license_id", null: false
    t.datetime "last_heartbeat_at", precision: nil
    t.integer "cores"
    t.datetime "last_death_event_sent_at", precision: nil
    t.uuid "group_id"
    t.integer "max_processes_override"
    t.datetime "last_check_out_at", precision: nil
    t.uuid "environment_id"
    t.string "heartbeat_jid"
    t.index "license_id, md5((fingerprint)::text)", name: "machines_license_id_fingerprint_unique_idx", unique: true
    t.index "to_tsvector('simple'::regconfig, COALESCE((id)::text, ''::text))", name: "machines_tsv_id_idx", using: :gist
    t.index "to_tsvector('simple'::regconfig, COALESCE((metadata)::text, ''::text))", name: "machines_tsv_metadata_idx", using: :gist
    t.index "to_tsvector('simple'::regconfig, COALESCE((name)::text, ''::text))", name: "machines_tsv_name_idx", using: :gist
    t.index ["account_id", "created_at"], name: "index_machines_on_account_id_and_created_at"
    t.index ["created_at"], name: "index_machines_on_created_at", order: :desc
    t.index ["environment_id"], name: "index_machines_on_environment_id"
    t.index ["fingerprint"], name: "machines_hash_fingerprint_idx", using: :hash
    t.index ["group_id"], name: "index_machines_on_group_id"
    t.index ["heartbeat_jid"], name: "index_machines_on_heartbeat_jid"
    t.index ["id", "created_at", "account_id"], name: "index_machines_on_id_and_created_at_and_account_id", unique: true
    t.index ["last_heartbeat_at"], name: "index_machines_on_last_heartbeat_at"
    t.index ["license_id", "created_at"], name: "index_machines_on_license_id_and_created_at"
  end

  create_table "metrics", id: :uuid, default: -> { "uuid_generate_v4()" }, force: :cascade do |t|
    t.uuid "account_id"
    t.jsonb "data"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.uuid "event_type_id", null: false
    t.date "created_date", null: false
    t.index ["account_id", "created_at", "event_type_id"], name: "metrics_account_created_event_type_idx", order: { created_at: :desc }, where: "(event_type_id <> ALL (ARRAY['b4d4a9ff-1a63-4d5f-b95f-617788fb50dc'::uuid, 'a0a302c6-2872-4983-b815-391a5022d469'::uuid, '918f5d37-7369-454e-a5e5-9385a46f184a'::uuid, 'ac3e4f4b-712c-4cce-aa33-81788d4c4fbf'::uuid, '7b14b995-2a2b-4f1f-9628-16a3bc9e8d76'::uuid, 'cbd8b04c-1fd7-41b9-b11d-74c9deb60c77'::uuid, 'b4e5d6f2-25ff-46fb-9e1e-91ead72c0ccc'::uuid, 'ebb19f81-ca0f-4af4-bdbe-7476b22778ba'::uuid, '6f75f2c4-6451-405a-a389-fa029137f6f0'::uuid]))"
    t.index ["account_id", "created_at", "event_type_id"], name: "metrics_high_vol_account_created_event_type_idx", order: { created_at: :desc }, where: "(event_type_id = ANY (ARRAY['b4d4a9ff-1a63-4d5f-b95f-617788fb50dc'::uuid, 'a0a302c6-2872-4983-b815-391a5022d469'::uuid, '918f5d37-7369-454e-a5e5-9385a46f184a'::uuid, 'ac3e4f4b-712c-4cce-aa33-81788d4c4fbf'::uuid, '7b14b995-2a2b-4f1f-9628-16a3bc9e8d76'::uuid, 'cbd8b04c-1fd7-41b9-b11d-74c9deb60c77'::uuid, 'b4e5d6f2-25ff-46fb-9e1e-91ead72c0ccc'::uuid, 'ebb19f81-ca0f-4af4-bdbe-7476b22778ba'::uuid]))"
    t.index ["account_id", "created_date", "event_type_id"], name: "metrics_hi_vol_acct_created_date_event_type_idx", order: { created_date: :desc }, where: "(event_type_id = ANY (ARRAY['b4d4a9ff-1a63-4d5f-b95f-617788fb50dc'::uuid, 'a0a302c6-2872-4983-b815-391a5022d469'::uuid, '918f5d37-7369-454e-a5e5-9385a46f184a'::uuid, 'ac3e4f4b-712c-4cce-aa33-81788d4c4fbf'::uuid, 'e84ab2b7-efd8-42f9-87be-1f3aa34b3e42'::uuid, '2634100c-40aa-4879-a84d-8d9878573efc'::uuid]))"
    t.index ["account_id", "created_date", "event_type_id"], name: "metrics_lo_vol_acct_created_date_event_type_idx", order: { created_date: :desc }, where: "(event_type_id <> ALL (ARRAY['b4d4a9ff-1a63-4d5f-b95f-617788fb50dc'::uuid, 'a0a302c6-2872-4983-b815-391a5022d469'::uuid, '918f5d37-7369-454e-a5e5-9385a46f184a'::uuid, 'ac3e4f4b-712c-4cce-aa33-81788d4c4fbf'::uuid, 'e84ab2b7-efd8-42f9-87be-1f3aa34b3e42'::uuid, '2634100c-40aa-4879-a84d-8d9878573efc'::uuid]))"
    t.index ["account_id", "created_date"], name: "index_metrics_on_account_id_and_created_date", order: { created_date: :desc }
    t.index ["account_id"], name: "index_metrics_on_account_id"
    t.index ["created_at"], name: "index_metrics_on_created_at", order: :desc
    t.index ["event_type_id"], name: "index_metrics_on_event_type_id"
  end

  create_table "permissions", id: :uuid, default: -> { "uuid_generate_v4()" }, force: :cascade do |t|
    t.string "action", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["action"], name: "index_permissions_on_action", unique: true
  end

  create_table "plans", id: :uuid, default: -> { "uuid_generate_v4()" }, force: :cascade do |t|
    t.string "name"
    t.integer "price"
    t.integer "max_users"
    t.integer "max_policies"
    t.integer "max_licenses"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
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
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.integer "lock_version", default: 0, null: false
    t.integer "max_machines"
    t.boolean "encrypted", default: false
    t.boolean "protected"
    t.jsonb "metadata"
    t.uuid "product_id", null: false
    t.uuid "account_id", null: false
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
    t.string "expiration_strategy"
    t.string "expiration_basis"
    t.string "authentication_strategy"
    t.string "heartbeat_cull_strategy"
    t.string "heartbeat_resurrection_strategy"
    t.boolean "require_heartbeat", default: false, null: false
    t.string "transfer_strategy"
    t.boolean "require_user_scope", default: false, null: false
    t.string "leasing_strategy"
    t.integer "max_processes"
    t.string "overage_strategy"
    t.uuid "environment_id"
    t.string "heartbeat_basis"
    t.boolean "require_environment_scope", default: false, null: false
    t.boolean "require_checksum_scope", default: false, null: false
    t.boolean "require_version_scope", default: false, null: false
    t.boolean "require_components_scope", default: false, null: false
    t.string "machine_uniqueness_strategy"
    t.string "machine_matching_strategy"
    t.string "component_uniqueness_strategy"
    t.string "component_matching_strategy"
    t.string "renewal_basis"
    t.index "to_tsvector('simple'::regconfig, COALESCE((id)::text, ''::text))", name: "policies_tsv_id_idx", using: :gist
    t.index "to_tsvector('simple'::regconfig, COALESCE((metadata)::text, ''::text))", name: "policies_tsv_metadata_idx", using: :gist
    t.index "to_tsvector('simple'::regconfig, COALESCE((name)::text, ''::text))", name: "policies_tsv_name_idx", using: :gist
    t.index ["account_id", "created_at"], name: "index_policies_on_account_id_and_created_at"
    t.index ["created_at"], name: "index_policies_on_created_at", order: :desc
    t.index ["environment_id"], name: "index_policies_on_environment_id"
    t.index ["id", "created_at", "account_id"], name: "index_policies_on_id_and_created_at_and_account_id", unique: true
    t.index ["product_id", "created_at"], name: "index_policies_on_product_id_and_created_at"
  end

  create_table "policy_entitlements", id: :uuid, default: -> { "uuid_generate_v4()" }, force: :cascade do |t|
    t.uuid "account_id", null: false
    t.uuid "policy_id", null: false
    t.uuid "entitlement_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.uuid "environment_id"
    t.index ["account_id", "policy_id", "entitlement_id"], name: "policy_entitlements_acct_lic_ent_ids_idx", unique: true
    t.index ["entitlement_id"], name: "index_policy_entitlements_on_entitlement_id"
    t.index ["environment_id"], name: "index_policy_entitlements_on_environment_id"
    t.index ["policy_id"], name: "index_policy_entitlements_on_policy_id"
  end

  create_table "products", id: :uuid, default: -> { "uuid_generate_v4()" }, force: :cascade do |t|
    t.string "name"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.jsonb "platforms"
    t.jsonb "metadata"
    t.uuid "account_id", null: false
    t.string "url"
    t.string "distribution_strategy"
    t.uuid "environment_id"
    t.index "to_tsvector('simple'::regconfig, COALESCE((id)::text, ''::text))", name: "products_tsv_id_idx", using: :gist
    t.index "to_tsvector('simple'::regconfig, COALESCE((metadata)::text, ''::text))", name: "products_tsv_metadata_idx", using: :gist
    t.index "to_tsvector('simple'::regconfig, COALESCE((name)::text, ''::text))", name: "products_tsv_name_idx", using: :gist
    t.index ["account_id", "created_at"], name: "index_products_on_account_id_and_created_at"
    t.index ["created_at"], name: "index_products_on_created_at", order: :desc
    t.index ["distribution_strategy"], name: "index_products_on_distribution_strategy"
    t.index ["environment_id"], name: "index_products_on_environment_id"
    t.index ["id", "created_at", "account_id"], name: "index_products_on_id_and_created_at_and_account_id", unique: true
  end

  create_table "receipts", id: :uuid, default: -> { "uuid_generate_v4()" }, force: :cascade do |t|
    t.string "invoice_id"
    t.integer "amount"
    t.boolean "paid"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.uuid "billing_id"
    t.index ["billing_id", "created_at"], name: "index_receipts_on_billing_id_and_created_at"
    t.index ["created_at"], name: "index_receipts_on_created_at", order: :desc
    t.index ["id", "created_at"], name: "index_receipts_on_id_and_created_at", unique: true
  end

  create_table "release_arches", id: :uuid, default: -> { "uuid_generate_v4()" }, force: :cascade do |t|
    t.uuid "account_id", null: false
    t.string "name"
    t.string "key"
    t.jsonb "metadata"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["account_id", "created_at"], name: "index_release_arches_on_account_id_and_created_at", order: { created_at: :desc }
    t.index ["account_id", "key"], name: "index_release_arches_on_account_id_and_key", unique: true
  end

  create_table "release_artifacts", id: :uuid, default: -> { "uuid_generate_v4()" }, force: :cascade do |t|
    t.uuid "account_id", null: false
    t.uuid "release_id", null: false
    t.string "filename"
    t.string "etag"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "content_length"
    t.string "content_type"
    t.uuid "release_platform_id"
    t.uuid "release_filetype_id"
    t.bigint "filesize"
    t.string "signature"
    t.string "checksum"
    t.uuid "release_arch_id"
    t.string "status"
    t.jsonb "metadata"
    t.string "backend"
    t.uuid "environment_id"
    t.index ["created_at"], name: "index_release_artifacts_on_created_at", order: :desc
    t.index ["environment_id"], name: "index_release_artifacts_on_environment_id"
    t.index ["filename", "release_id", "account_id"], name: "release_artifacts_uniq_filename_idx", unique: true, where: "(filename IS NOT NULL)"
    t.index ["release_arch_id"], name: "index_release_artifacts_on_release_arch_id"
    t.index ["release_filetype_id"], name: "index_release_artifacts_on_release_filetype_id"
    t.index ["release_platform_id"], name: "index_release_artifacts_on_release_platform_id"
    t.index ["status"], name: "index_release_artifacts_on_status"
  end

  create_table "release_channels", id: :uuid, default: -> { "uuid_generate_v4()" }, force: :cascade do |t|
    t.uuid "account_id", null: false
    t.string "name"
    t.string "key"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["account_id", "created_at"], name: "index_release_channels_on_account_id_and_created_at", order: { created_at: :desc }
    t.index ["account_id", "key"], name: "index_release_channels_on_account_id_and_key", unique: true
  end

  create_table "release_download_links", id: :uuid, default: -> { "uuid_generate_v4()" }, force: :cascade do |t|
    t.uuid "account_id", null: false
    t.uuid "release_id", null: false
    t.text "url"
    t.integer "ttl"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.uuid "environment_id"
    t.index ["account_id", "created_at"], name: "index_release_download_links_on_account_id_and_created_at", order: { created_at: :desc }
    t.index ["environment_id"], name: "index_release_download_links_on_environment_id"
    t.index ["release_id"], name: "index_release_download_links_on_release_id"
  end

  create_table "release_engines", id: :uuid, default: -> { "uuid_generate_v4()" }, force: :cascade do |t|
    t.uuid "account_id", null: false
    t.string "name"
    t.string "key", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["account_id", "created_at"], name: "index_release_engines_on_account_id_and_created_at", order: { created_at: :desc }
    t.index ["account_id", "key"], name: "index_release_engines_on_account_id_and_key", unique: true
  end

  create_table "release_entitlement_constraints", id: :uuid, default: -> { "uuid_generate_v4()" }, force: :cascade do |t|
    t.uuid "account_id", null: false
    t.uuid "release_id", null: false
    t.uuid "entitlement_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.uuid "environment_id"
    t.index ["account_id", "created_at"], name: "release_entls_acct_created_idx", order: { created_at: :desc }
    t.index ["account_id", "release_id", "entitlement_id"], name: "release_entls_acct_rel_ent_ids_idx", unique: true
    t.index ["entitlement_id"], name: "index_release_entitlement_constraints_on_entitlement_id"
    t.index ["environment_id"], name: "index_release_entitlement_constraints_on_environment_id"
    t.index ["release_id"], name: "index_release_entitlement_constraints_on_release_id"
  end

  create_table "release_filetypes", id: :uuid, default: -> { "uuid_generate_v4()" }, force: :cascade do |t|
    t.uuid "account_id", null: false
    t.string "name"
    t.string "key"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["account_id", "created_at"], name: "index_release_filetypes_on_account_id_and_created_at", order: { created_at: :desc }
    t.index ["account_id", "key"], name: "index_release_filetypes_on_account_id_and_key", unique: true
  end

  create_table "release_packages", id: :uuid, default: -> { "uuid_generate_v4()" }, force: :cascade do |t|
    t.uuid "account_id", null: false
    t.uuid "product_id", null: false
    t.uuid "release_engine_id"
    t.uuid "environment_id"
    t.string "name", null: false
    t.string "key", null: false
    t.jsonb "metadata"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["account_id", "created_at"], name: "index_release_packages_on_account_id_and_created_at", order: { created_at: :desc }
    t.index ["account_id", "key"], name: "index_release_packages_on_account_id_and_key", unique: true
    t.index ["environment_id"], name: "index_release_packages_on_environment_id"
    t.index ["product_id"], name: "index_release_packages_on_product_id"
    t.index ["release_engine_id"], name: "index_release_packages_on_release_engine_id"
  end

  create_table "release_platforms", id: :uuid, default: -> { "uuid_generate_v4()" }, force: :cascade do |t|
    t.uuid "account_id", null: false
    t.string "name"
    t.string "key"
    t.jsonb "metadata"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["account_id", "created_at"], name: "index_release_platforms_on_account_id_and_created_at", order: { created_at: :desc }
    t.index ["account_id", "key"], name: "index_release_platforms_on_account_id_and_key", unique: true
  end

  create_table "release_upgrade_links", id: :uuid, default: -> { "uuid_generate_v4()" }, force: :cascade do |t|
    t.uuid "account_id", null: false
    t.uuid "release_id", null: false
    t.text "url"
    t.integer "ttl"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.uuid "environment_id"
    t.index ["account_id", "created_at"], name: "index_release_upgrade_links_on_account_id_and_created_at", order: { created_at: :desc }
    t.index ["environment_id"], name: "index_release_upgrade_links_on_environment_id"
    t.index ["release_id"], name: "index_release_upgrade_links_on_release_id"
  end

  create_table "release_upload_links", id: :uuid, default: -> { "uuid_generate_v4()" }, force: :cascade do |t|
    t.uuid "account_id", null: false
    t.uuid "release_id", null: false
    t.text "url"
    t.integer "ttl"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.uuid "environment_id"
    t.index ["account_id", "created_at"], name: "index_release_upload_links_on_account_id_and_created_at", order: { created_at: :desc }
    t.index ["environment_id"], name: "index_release_upload_links_on_environment_id"
    t.index ["release_id"], name: "index_release_upload_links_on_release_id"
  end

  create_table "releases", id: :uuid, default: -> { "uuid_generate_v4()" }, force: :cascade do |t|
    t.uuid "account_id", null: false
    t.uuid "product_id", null: false
    t.uuid "release_platform_id"
    t.uuid "release_channel_id", null: false
    t.string "name"
    t.string "version"
    t.string "filename"
    t.bigint "filesize"
    t.bigint "download_count", default: 0
    t.jsonb "metadata"
    t.datetime "yanked_at", precision: nil
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "upgrade_count", default: 0
    t.uuid "release_filetype_id"
    t.text "description"
    t.string "signature"
    t.string "checksum"
    t.string "status"
    t.string "api_version"
    t.bigint "semver_major"
    t.bigint "semver_minor"
    t.bigint "semver_patch"
    t.string "semver_pre_word"
    t.bigint "semver_pre_num"
    t.string "semver_build_word"
    t.bigint "semver_build_num"
    t.string "tag"
    t.uuid "environment_id"
    t.uuid "release_package_id"
    t.index ["account_id", "created_at", "yanked_at"], name: "index_releases_on_account_id_and_created_at_and_yanked_at", order: { created_at: :desc }
    t.index ["account_id", "product_id", "filename"], name: "index_releases_on_account_id_and_product_id_and_filename", unique: true
    t.index ["environment_id"], name: "index_releases_on_environment_id"
    t.index ["product_id"], name: "index_releases_on_product_id"
    t.index ["release_channel_id"], name: "index_releases_on_release_channel_id"
    t.index ["release_filetype_id"], name: "index_releases_on_release_filetype_id"
    t.index ["release_package_id"], name: "index_releases_on_release_package_id"
    t.index ["release_platform_id"], name: "index_releases_on_release_platform_id"
    t.index ["semver_major", "semver_minor", "semver_patch", "semver_pre_word", "semver_pre_num", "semver_build_word", "semver_build_num"], name: "releases_sort_semver_components_idx", order: { semver_major: :desc, semver_minor: "DESC NULLS LAST", semver_patch: "DESC NULLS LAST", semver_pre_word: :desc, semver_pre_num: "DESC NULLS LAST", semver_build_word: "DESC NULLS LAST", semver_build_num: "DESC NULLS LAST" }
    t.index ["status"], name: "index_releases_on_status"
    t.index ["tag", "account_id"], name: "index_releases_on_tag_and_account_id", unique: true, where: "(tag IS NOT NULL)"
    t.index ["version", "product_id", "account_id"], name: "releases_version_no_package_uniq_idx", unique: true, where: "((release_package_id IS NULL) AND ((api_version)::text <> '1.0'::text))"
    t.index ["version", "release_package_id", "product_id", "account_id"], name: "releases_version_package_uniq_idx", unique: true, where: "((release_package_id IS NOT NULL) AND ((api_version)::text <> '1.0'::text))"
  end

  create_table "request_logs", id: :uuid, default: -> { "uuid_generate_v4()" }, force: :cascade do |t|
    t.uuid "account_id"
    t.string "url"
    t.string "method"
    t.string "ip"
    t.string "user_agent"
    t.string "status"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.string "requestor_type"
    t.uuid "requestor_id"
    t.text "request_body"
    t.text "response_body"
    t.text "response_signature"
    t.string "resource_type"
    t.uuid "resource_id"
    t.date "created_date", null: false
    t.uuid "environment_id"
    t.jsonb "request_headers"
    t.jsonb "response_headers"
    t.float "run_time"
    t.float "queue_time"
    t.index ["account_id", "created_at"], name: "index_request_logs_on_account_id_and_created_at"
    t.index ["account_id", "created_date"], name: "index_request_logs_on_account_id_and_created_date", order: { created_date: :desc }
    t.index ["environment_id"], name: "index_request_logs_on_environment_id"
    t.index ["method"], name: "request_logs_method_idx"
    t.index ["requestor_id", "requestor_type"], name: "request_logs_requestor_idx"
    t.index ["status"], name: "request_logs_status_idx"
  end

  create_table "role_permissions", id: :uuid, default: -> { "uuid_generate_v4()" }, force: :cascade do |t|
    t.uuid "permission_id", null: false
    t.uuid "role_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["permission_id"], name: "index_role_permissions_on_permission_id"
    t.index ["role_id", "permission_id"], name: "index_role_permissions_on_role_id_and_permission_id", unique: true
  end

  create_table "roles", id: :uuid, default: -> { "uuid_generate_v4()" }, force: :cascade do |t|
    t.string "name"
    t.string "resource_type"
    t.datetime "created_at", precision: nil
    t.datetime "updated_at", precision: nil
    t.uuid "resource_id"
    t.index ["created_at"], name: "index_roles_on_created_at", order: :desc
    t.index ["id", "created_at"], name: "index_roles_on_id_and_created_at", unique: true
    t.index ["name", "created_at"], name: "index_roles_on_name_and_created_at"
    t.index ["resource_id", "resource_type", "created_at"], name: "index_roles_on_resource_id_and_resource_type_and_created_at"
    t.index ["resource_type", "resource_id", "name"], name: "index_roles_on_resource_type_and_resource_id_and_name"
  end

  create_table "second_factors", id: :uuid, default: -> { "uuid_generate_v4()" }, force: :cascade do |t|
    t.uuid "account_id", null: false
    t.uuid "user_id", null: false
    t.text "secret", null: false
    t.boolean "enabled", default: false, null: false
    t.datetime "last_verified_at", precision: nil
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.uuid "environment_id"
    t.index ["account_id", "created_at"], name: "index_second_factors_on_account_id_and_created_at"
    t.index ["environment_id"], name: "index_second_factors_on_environment_id"
    t.index ["id", "created_at"], name: "index_second_factors_on_id_and_created_at", unique: true
    t.index ["secret"], name: "index_second_factors_on_secret", unique: true
    t.index ["user_id"], name: "index_second_factors_on_user_id", unique: true
  end

  create_table "token_permissions", id: :uuid, default: -> { "uuid_generate_v4()" }, force: :cascade do |t|
    t.uuid "permission_id", null: false
    t.uuid "token_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["permission_id"], name: "index_token_permissions_on_permission_id"
    t.index ["token_id", "permission_id"], name: "index_token_permissions_on_token_id_and_permission_id", unique: true
  end

  create_table "tokens", id: :uuid, default: -> { "uuid_generate_v4()" }, force: :cascade do |t|
    t.string "digest"
    t.string "bearer_type"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.datetime "expiry", precision: nil
    t.uuid "bearer_id"
    t.uuid "account_id"
    t.integer "max_activations"
    t.integer "max_deactivations"
    t.integer "activations", default: 0
    t.integer "deactivations", default: 0
    t.string "name"
    t.uuid "environment_id"
    t.index ["account_id", "created_at"], name: "index_tokens_on_account_id_and_created_at"
    t.index ["bearer_id", "bearer_type", "created_at"], name: "index_tokens_on_bearer_id_and_bearer_type_and_created_at"
    t.index ["created_at"], name: "index_tokens_on_created_at", order: :desc
    t.index ["digest"], name: "index_tokens_on_digest", unique: true
    t.index ["environment_id"], name: "index_tokens_on_environment_id"
    t.index ["id", "created_at", "account_id"], name: "index_tokens_on_id_and_created_at_and_account_id", unique: true
  end

  create_table "users", id: :uuid, default: -> { "uuid_generate_v4()" }, force: :cascade do |t|
    t.string "email"
    t.string "password_digest"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.string "password_reset_token"
    t.datetime "password_reset_sent_at", precision: nil
    t.jsonb "metadata"
    t.uuid "account_id", null: false
    t.string "first_name"
    t.string "last_name"
    t.datetime "stdout_unsubscribed_at", precision: nil
    t.datetime "stdout_last_sent_at", precision: nil
    t.datetime "banned_at", precision: nil
    t.uuid "group_id"
    t.uuid "environment_id"
    t.index "to_tsvector('simple'::regconfig, COALESCE((first_name)::text, ''::text))", name: "users_tsv_first_name_idx", using: :gist
    t.index "to_tsvector('simple'::regconfig, COALESCE((id)::text, ''::text))", name: "users_tsv_id_idx", using: :gist
    t.index "to_tsvector('simple'::regconfig, COALESCE((last_name)::text, ''::text))", name: "users_tsv_last_name_idx", using: :gist
    t.index "to_tsvector('simple'::regconfig, COALESCE((metadata)::text, ''::text))", name: "users_tsv_metadata_idx", using: :gist
    t.index ["account_id", "created_at"], name: "index_users_on_account_id_and_created_at"
    t.index ["banned_at"], name: "index_users_on_banned_at"
    t.index ["created_at"], name: "index_users_on_created_at", order: :desc
    t.index ["email", "account_id"], name: "index_users_on_email_and_account_id", unique: true
    t.index ["environment_id"], name: "index_users_on_environment_id"
    t.index ["group_id"], name: "index_users_on_group_id"
    t.index ["id", "created_at", "account_id"], name: "index_users_on_id_and_created_at_and_account_id", unique: true
  end

  create_table "webhook_endpoints", id: :uuid, default: -> { "uuid_generate_v4()" }, force: :cascade do |t|
    t.string "url"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.uuid "account_id"
    t.jsonb "subscriptions", default: ["*"]
    t.string "signature_algorithm", default: "ed25519"
    t.string "api_version"
    t.uuid "environment_id"
    t.index ["account_id", "created_at"], name: "index_webhook_endpoints_on_account_id_and_created_at"
    t.index ["created_at"], name: "index_webhook_endpoints_on_created_at", order: :desc
    t.index ["environment_id"], name: "index_webhook_endpoints_on_environment_id"
    t.index ["id", "created_at", "account_id"], name: "index_webhook_endpoints_on_id_and_created_at_and_account_id", unique: true
  end

  create_table "webhook_events", id: :uuid, default: -> { "uuid_generate_v4()" }, force: :cascade do |t|
    t.text "payload"
    t.string "jid"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.string "endpoint"
    t.uuid "account_id"
    t.string "idempotency_token"
    t.integer "last_response_code"
    t.text "last_response_body"
    t.uuid "event_type_id", null: false
    t.string "status"
    t.string "api_version"
    t.uuid "environment_id"
    t.index ["account_id", "created_at"], name: "index_webhook_events_on_account_id_and_created_at", order: { created_at: :desc }
    t.index ["environment_id"], name: "index_webhook_events_on_environment_id"
    t.index ["event_type_id"], name: "index_webhook_events_on_event_type_id"
    t.index ["id", "created_at", "account_id"], name: "index_webhook_events_on_id_and_created_at_and_account_id", unique: true
    t.index ["idempotency_token"], name: "index_webhook_events_on_idempotency_token"
    t.index ["jid", "created_at", "account_id"], name: "index_webhook_events_on_jid_and_created_at_and_account_id"
  end

end
