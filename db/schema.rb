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

ActiveRecord::Schema.define(version: 20170509144501) do

  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"
  enable_extension "uuid-ossp"

  create_table "accounts", id: :uuid, default: -> { "uuid_generate_v4()" }, force: :cascade do |t|
    t.string   "name"
    t.datetime "created_at",                 null: false
    t.datetime "updated_at",                 null: false
    t.string   "slug"
    t.uuid     "plan_id"
    t.boolean  "protected",  default: false
    t.index ["created_at", "id", "slug"], name: "index_accounts_on_created_at_and_id_and_slug", unique: true, using: :btree
    t.index ["created_at", "plan_id"], name: "index_accounts_on_created_at_and_plan_id", using: :btree
    t.index ["created_at", "slug"], name: "index_accounts_on_created_at_and_slug", unique: true, using: :btree
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
    t.index ["created_at", "account_id"], name: "index_billings_on_created_at_and_account_id", using: :btree
    t.index ["created_at", "customer_id"], name: "index_billings_on_created_at_and_customer_id", using: :btree
    t.index ["created_at", "id"], name: "index_billings_on_created_at_and_id", unique: true, using: :btree
    t.index ["created_at", "subscription_id"], name: "index_billings_on_created_at_and_subscription_id", using: :btree
  end

  create_table "keys", id: :uuid, default: -> { "uuid_generate_v4()" }, force: :cascade do |t|
    t.string   "key"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.uuid     "policy_id"
    t.uuid     "account_id"
    t.index ["created_at", "account_id"], name: "index_keys_on_created_at_and_account_id", using: :btree
    t.index ["created_at", "id"], name: "index_keys_on_created_at_and_id", unique: true, using: :btree
    t.index ["created_at", "policy_id"], name: "index_keys_on_created_at_and_policy_id", using: :btree
  end

  create_table "licenses", id: :uuid, default: -> { "uuid_generate_v4()" }, force: :cascade do |t|
    t.string   "key"
    t.datetime "expiry"
    t.datetime "created_at",                 null: false
    t.datetime "updated_at",                 null: false
    t.jsonb    "metadata"
    t.uuid     "user_id"
    t.uuid     "policy_id"
    t.uuid     "account_id"
    t.boolean  "suspended",  default: false
    t.index ["created_at", "account_id"], name: "index_licenses_on_created_at_and_account_id", using: :btree
    t.index ["created_at", "id"], name: "index_licenses_on_created_at_and_id", unique: true, using: :btree
    t.index ["created_at", "policy_id"], name: "index_licenses_on_created_at_and_policy_id", using: :btree
    t.index ["created_at", "user_id"], name: "index_licenses_on_created_at_and_user_id", using: :btree
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
    t.index ["created_at", "account_id"], name: "index_machines_on_created_at_and_account_id", using: :btree
    t.index ["created_at", "id"], name: "index_machines_on_created_at_and_id", unique: true, using: :btree
    t.index ["created_at", "license_id"], name: "index_machines_on_created_at_and_license_id", using: :btree
  end

  create_table "metrics", id: :uuid, default: -> { "uuid_generate_v4()" }, force: :cascade do |t|
    t.uuid     "account_id"
    t.string   "metric"
    t.jsonb    "data"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["created_at", "account_id"], name: "index_metrics_on_created_at_and_account_id", using: :btree
    t.index ["created_at", "id"], name: "index_metrics_on_created_at_and_id", unique: true, using: :btree
  end

  create_table "plans", id: :uuid, default: -> { "uuid_generate_v4()" }, force: :cascade do |t|
    t.string   "name"
    t.integer  "price"
    t.integer  "max_users"
    t.integer  "max_policies"
    t.integer  "max_licenses"
    t.datetime "created_at",                   null: false
    t.datetime "updated_at",                   null: false
    t.integer  "max_products"
    t.string   "plan_id"
    t.boolean  "private",      default: false
    t.index ["created_at", "id"], name: "index_plans_on_created_at_and_id", unique: true, using: :btree
    t.index ["created_at", "plan_id"], name: "index_plans_on_created_at_and_plan_id", using: :btree
  end

  create_table "policies", id: :uuid, default: -> { "uuid_generate_v4()" }, force: :cascade do |t|
    t.string   "name"
    t.integer  "duration"
    t.boolean  "strict",       default: false
    t.boolean  "floating",     default: false
    t.boolean  "use_pool",     default: false
    t.datetime "created_at",                   null: false
    t.datetime "updated_at",                   null: false
    t.integer  "lock_version", default: 0,     null: false
    t.integer  "max_machines", default: 1
    t.boolean  "encrypted",    default: false
    t.boolean  "protected",    default: false
    t.jsonb    "metadata"
    t.uuid     "product_id"
    t.uuid     "account_id"
    t.index ["created_at", "account_id"], name: "index_policies_on_created_at_and_account_id", using: :btree
    t.index ["created_at", "id"], name: "index_policies_on_created_at_and_id", unique: true, using: :btree
    t.index ["created_at", "product_id"], name: "index_policies_on_created_at_and_product_id", using: :btree
  end

  create_table "products", id: :uuid, default: -> { "uuid_generate_v4()" }, force: :cascade do |t|
    t.string   "name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.jsonb    "platforms"
    t.jsonb    "metadata"
    t.uuid     "account_id"
    t.index ["created_at", "account_id"], name: "index_products_on_created_at_and_account_id", using: :btree
    t.index ["created_at", "id"], name: "index_products_on_created_at_and_id", unique: true, using: :btree
  end

  create_table "receipts", id: :uuid, default: -> { "uuid_generate_v4()" }, force: :cascade do |t|
    t.string   "invoice_id"
    t.integer  "amount"
    t.boolean  "paid"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.uuid     "billing_id"
    t.index ["created_at", "billing_id"], name: "index_receipts_on_created_at_and_billing_id", using: :btree
    t.index ["created_at", "id"], name: "index_receipts_on_created_at_and_id", unique: true, using: :btree
  end

  create_table "roles", id: :uuid, default: -> { "uuid_generate_v4()" }, force: :cascade do |t|
    t.string   "name"
    t.string   "resource_type"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.uuid     "resource_id"
    t.index ["created_at", "id"], name: "index_roles_on_created_at_and_id", unique: true, using: :btree
    t.index ["created_at", "name"], name: "index_roles_on_created_at_and_name", using: :btree
    t.index ["created_at", "resource_id", "resource_type"], name: "index_roles_on_created_at_and_resource_id_and_resource_type", using: :btree
  end

  create_table "tokens", id: :uuid, default: -> { "uuid_generate_v4()" }, force: :cascade do |t|
    t.string   "digest"
    t.string   "bearer_type"
    t.datetime "created_at",  null: false
    t.datetime "updated_at",  null: false
    t.datetime "expiry"
    t.uuid     "bearer_id"
    t.uuid     "account_id"
    t.index ["created_at", "account_id"], name: "index_tokens_on_created_at_and_account_id", using: :btree
    t.index ["created_at", "bearer_id", "bearer_type"], name: "index_tokens_on_created_at_and_bearer_id_and_bearer_type", using: :btree
    t.index ["created_at", "id"], name: "index_tokens_on_created_at_and_id", unique: true, using: :btree
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
    t.index ["created_at", "account_id", "email"], name: "index_users_on_created_at_and_account_id_and_email", using: :btree
    t.index ["created_at", "account_id"], name: "index_users_on_created_at_and_account_id", using: :btree
    t.index ["created_at", "id"], name: "index_users_on_created_at_and_id", unique: true, using: :btree
  end

  create_table "webhook_endpoints", id: :uuid, default: -> { "uuid_generate_v4()" }, force: :cascade do |t|
    t.string   "url"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.uuid     "account_id"
    t.index ["created_at", "account_id"], name: "index_webhook_endpoints_on_created_at_and_account_id", using: :btree
    t.index ["created_at", "id"], name: "index_webhook_endpoints_on_created_at_and_id", unique: true, using: :btree
  end

  create_table "webhook_events", id: :uuid, default: -> { "uuid_generate_v4()" }, force: :cascade do |t|
    t.text     "payload"
    t.string   "jid"
    t.datetime "created_at",        null: false
    t.datetime "updated_at",        null: false
    t.string   "endpoint"
    t.uuid     "account_id"
    t.string   "idempotency_token"
    t.string   "event"
    t.index ["created_at", "account_id"], name: "index_webhook_events_on_created_at_and_account_id", using: :btree
    t.index ["created_at", "id"], name: "index_webhook_events_on_created_at_and_id", unique: true, using: :btree
    t.index ["created_at", "jid"], name: "index_webhook_events_on_created_at_and_jid", using: :btree
  end

end
