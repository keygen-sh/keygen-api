# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# Note that this schema.rb definition is the authoritative source for your
# database schema. If you need to create the application database on another
# system, you should be using db:schema:load, not running all the migrations
# from scratch. The latter is a flawed and unsustainable approach (the more migrations
# you'll amass, the slower it'll run and the greater likelihood for issues).
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema.define(version: 20180511152944) do

  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"
  enable_extension "uuid-ossp"
  enable_extension "pg_stat_statements"

  create_table "accounts", id: :uuid, default: -> { "uuid_generate_v4()" }, force: :cascade do |t|
    t.string   "name"
    t.string   "slug"
    t.datetime "created_at",                  null: false
    t.datetime "updated_at",                  null: false
    t.uuid     "plan_id"
    t.boolean  "protected",   default: false
    t.text     "public_key"
    t.text     "private_key"
    t.index ["id", "created_at"], name: "index_accounts_on_id_and_created_at", unique: true, using: :btree
    t.index ["plan_id", "created_at"], name: "index_accounts_on_plan_id_and_created_at", using: :btree
    t.index ["slug", "created_at"], name: "index_accounts_on_slug_and_created_at", unique: true, using: :btree
    t.index ["slug"], name: "index_accounts_on_slug", unique: true, using: :btree
  end

  create_table "billings", id: :uuid, default: -> { "uuid_generate_v4()" }, force: :cascade do |t|
    t.string   "customer_id"
    t.string   "subscription_status"
    t.datetime "created_at",                null: false
    t.datetime "updated_at",                null: false
    t.string   "subscription_id"
    t.datetime "subscription_period_start"
    t.datetime "subscription_period_end"
    t.datetime "card_expiry"
    t.string   "card_brand"
    t.string   "card_last4"
    t.string   "state"
    t.uuid     "account_id"
    t.index ["account_id", "created_at"], name: "index_billings_on_account_id_and_created_at", using: :btree
    t.index ["customer_id", "created_at"], name: "index_billings_on_customer_id_and_created_at", using: :btree
    t.index ["id", "created_at"], name: "index_billings_on_id_and_created_at", unique: true, using: :btree
    t.index ["subscription_id", "created_at"], name: "index_billings_on_subscription_id_and_created_at", using: :btree
  end

  create_table "keys", id: :uuid, default: -> { "uuid_generate_v4()" }, force: :cascade do |t|
    t.string   "key"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.uuid     "policy_id"
    t.uuid     "account_id"
    t.index ["account_id", "created_at"], name: "index_keys_on_account_id_and_created_at", using: :btree
    t.index ["id", "created_at", "account_id"], name: "index_keys_on_id_and_created_at_and_account_id", unique: true, using: :btree
    t.index ["policy_id", "created_at"], name: "index_keys_on_policy_id_and_created_at", using: :btree
  end

  create_table "licenses", id: :uuid, default: -> { "uuid_generate_v4()" }, force: :cascade do |t|
    t.string   "key"
    t.datetime "expiry"
    t.datetime "created_at",                                       null: false
    t.datetime "updated_at",                                       null: false
    t.jsonb    "metadata"
    t.uuid     "user_id"
    t.uuid     "policy_id"
    t.uuid     "account_id"
    t.boolean  "suspended",                        default: false
    t.datetime "last_check_in_at"
    t.datetime "last_expiration_event_sent_at"
    t.datetime "last_check_in_event_sent_at"
    t.datetime "last_expiring_soon_event_sent_at"
    t.datetime "last_check_in_soon_event_sent_at"
    t.integer  "uses",                             default: 0
    t.index ["account_id", "created_at"], name: "index_licenses_on_account_id_and_created_at", using: :btree
    t.index ["id", "created_at", "account_id"], name: "index_licenses_on_id_and_created_at_and_account_id", unique: true, using: :btree
    t.index ["key", "created_at", "account_id"], name: "index_licenses_on_key_and_created_at_and_account_id", using: :btree
    t.index ["policy_id", "created_at"], name: "index_licenses_on_policy_id_and_created_at", using: :btree
    t.index ["user_id", "created_at"], name: "index_licenses_on_user_id_and_created_at", using: :btree
  end

  create_table "machines", id: :uuid, default: -> { "uuid_generate_v4()" }, force: :cascade do |t|
    t.string   "fingerprint"
    t.string   "ip"
    t.string   "hostname"
    t.string   "platform"
    t.datetime "created_at",  null: false
    t.datetime "updated_at",  null: false
    t.string   "name"
    t.jsonb    "metadata"
    t.uuid     "account_id"
    t.uuid     "license_id"
    t.index ["account_id", "created_at"], name: "index_machines_on_account_id_and_created_at", using: :btree
    t.index ["id", "created_at", "account_id"], name: "index_machines_on_id_and_created_at_and_account_id", unique: true, using: :btree
    t.index ["license_id", "created_at"], name: "index_machines_on_license_id_and_created_at", using: :btree
  end

  create_table "metrics", id: :uuid, default: -> { "uuid_generate_v4()" }, force: :cascade do |t|
    t.uuid     "account_id"
    t.string   "metric"
    t.jsonb    "data"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["account_id", "created_at"], name: "index_metrics_on_account_id_and_created_at", using: :btree
    t.index ["id", "created_at"], name: "index_metrics_on_id_and_created_at", unique: true, using: :btree
  end

  create_table "plans", id: :uuid, default: -> { "uuid_generate_v4()" }, force: :cascade do |t|
    t.string   "name"
    t.integer  "price"
    t.integer  "max_users"
    t.integer  "max_policies"
    t.integer  "max_licenses"
    t.datetime "created_at",                     null: false
    t.datetime "updated_at",                     null: false
    t.integer  "max_products"
    t.string   "plan_id"
    t.boolean  "private",        default: false
    t.integer  "trial_duration"
    t.integer  "max_reqs"
    t.integer  "max_admins"
    t.index ["id", "created_at"], name: "index_plans_on_id_and_created_at", unique: true, using: :btree
    t.index ["plan_id", "created_at"], name: "index_plans_on_plan_id_and_created_at", using: :btree
  end

  create_table "policies", id: :uuid, default: -> { "uuid_generate_v4()" }, force: :cascade do |t|
    t.string   "name"
    t.integer  "duration"
    t.boolean  "strict",                    default: false
    t.boolean  "floating",                  default: false
    t.boolean  "use_pool",                  default: false
    t.datetime "created_at",                                null: false
    t.datetime "updated_at",                                null: false
    t.integer  "lock_version",              default: 0,     null: false
    t.integer  "max_machines"
    t.boolean  "encrypted",                 default: false
    t.boolean  "protected"
    t.jsonb    "metadata"
    t.uuid     "product_id"
    t.uuid     "account_id"
    t.string   "check_in_interval"
    t.integer  "check_in_interval_count"
    t.boolean  "require_check_in",          default: false
    t.boolean  "require_product_scope",     default: false
    t.boolean  "require_policy_scope",      default: false
    t.boolean  "require_machine_scope",     default: false
    t.boolean  "require_fingerprint_scope", default: false
    t.boolean  "concurrent",                default: true
    t.integer  "max_uses"
    t.index ["account_id", "created_at"], name: "index_policies_on_account_id_and_created_at", using: :btree
    t.index ["id", "created_at", "account_id"], name: "index_policies_on_id_and_created_at_and_account_id", unique: true, using: :btree
    t.index ["product_id", "created_at"], name: "index_policies_on_product_id_and_created_at", using: :btree
  end

  create_table "products", id: :uuid, default: -> { "uuid_generate_v4()" }, force: :cascade do |t|
    t.string   "name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.jsonb    "platforms"
    t.jsonb    "metadata"
    t.uuid     "account_id"
    t.string   "url"
    t.index ["account_id", "created_at"], name: "index_products_on_account_id_and_created_at", using: :btree
    t.index ["id", "created_at", "account_id"], name: "index_products_on_id_and_created_at_and_account_id", unique: true, using: :btree
  end

  create_table "receipts", id: :uuid, default: -> { "uuid_generate_v4()" }, force: :cascade do |t|
    t.string   "invoice_id"
    t.integer  "amount"
    t.boolean  "paid"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.uuid     "billing_id"
    t.index ["billing_id", "created_at"], name: "index_receipts_on_billing_id_and_created_at", using: :btree
    t.index ["id", "created_at"], name: "index_receipts_on_id_and_created_at", unique: true, using: :btree
  end

  create_table "roles", id: :uuid, default: -> { "uuid_generate_v4()" }, force: :cascade do |t|
    t.string   "name"
    t.string   "resource_type"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.uuid     "resource_id"
    t.index ["id", "created_at"], name: "index_roles_on_id_and_created_at", unique: true, using: :btree
    t.index ["name", "created_at"], name: "index_roles_on_name_and_created_at", using: :btree
    t.index ["resource_id", "resource_type", "created_at"], name: "index_roles_on_resource_id_and_resource_type_and_created_at", using: :btree
  end

  create_table "tokens", id: :uuid, default: -> { "uuid_generate_v4()" }, force: :cascade do |t|
    t.string   "digest"
    t.string   "bearer_type"
    t.datetime "created_at",                    null: false
    t.datetime "updated_at",                    null: false
    t.datetime "expiry"
    t.uuid     "bearer_id"
    t.uuid     "account_id"
    t.integer  "max_activations"
    t.integer  "max_deactivations"
    t.integer  "activations",       default: 0
    t.integer  "deactivations",     default: 0
    t.index ["account_id", "created_at"], name: "index_tokens_on_account_id_and_created_at", using: :btree
    t.index ["bearer_id", "bearer_type", "created_at"], name: "index_tokens_on_bearer_id_and_bearer_type_and_created_at", using: :btree
    t.index ["digest", "created_at", "account_id"], name: "index_tokens_on_digest_and_created_at_and_account_id", unique: true, using: :btree
    t.index ["id", "created_at", "account_id"], name: "index_tokens_on_id_and_created_at_and_account_id", unique: true, using: :btree
  end

  create_table "users", id: :uuid, default: -> { "uuid_generate_v4()" }, force: :cascade do |t|
    t.string   "email"
    t.string   "password_digest"
    t.datetime "created_at",             null: false
    t.datetime "updated_at",             null: false
    t.string   "password_reset_token"
    t.datetime "password_reset_sent_at"
    t.jsonb    "metadata"
    t.uuid     "account_id"
    t.string   "first_name"
    t.string   "last_name"
    t.index ["account_id", "created_at"], name: "index_users_on_account_id_and_created_at", using: :btree
    t.index ["email", "account_id", "created_at"], name: "index_users_on_email_and_account_id_and_created_at", using: :btree
    t.index ["id", "created_at", "account_id"], name: "index_users_on_id_and_created_at_and_account_id", unique: true, using: :btree
  end

  create_table "webhook_endpoints", id: :uuid, default: -> { "uuid_generate_v4()" }, force: :cascade do |t|
    t.string   "url"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.uuid     "account_id"
    t.index ["account_id", "created_at"], name: "index_webhook_endpoints_on_account_id_and_created_at", using: :btree
    t.index ["id", "created_at", "account_id"], name: "index_webhook_endpoints_on_id_and_created_at_and_account_id", unique: true, using: :btree
  end

  create_table "webhook_events", id: :uuid, default: -> { "uuid_generate_v4()" }, force: :cascade do |t|
    t.text     "payload"
    t.string   "jid"
    t.datetime "created_at",         null: false
    t.datetime "updated_at",         null: false
    t.string   "endpoint"
    t.uuid     "account_id"
    t.string   "idempotency_token"
    t.string   "event"
    t.integer  "last_response_code"
    t.text     "last_response_body"
    t.index ["account_id", "created_at"], name: "index_webhook_events_on_account_id_and_created_at", using: :btree
    t.index ["id", "created_at", "account_id"], name: "index_webhook_events_on_id_and_created_at_and_account_id", unique: true, using: :btree
    t.index ["idempotency_token"], name: "index_webhook_events_on_idempotency_token", using: :btree
    t.index ["jid", "created_at", "account_id"], name: "index_webhook_events_on_jid_and_created_at_and_account_id", using: :btree
  end

end
