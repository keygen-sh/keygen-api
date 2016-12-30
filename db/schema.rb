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

ActiveRecord::Schema.define(version: 20161230174909) do

  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"
  enable_extension "uuid-ossp"

  create_table "accounts", id: :uuid, default: -> { "uuid_generate_v4()" }, force: :cascade do |t|
    t.string   "name"
    t.string   "slug"
    t.datetime "created_at",         null: false
    t.datetime "updated_at",         null: false
    t.string   "activation_token"
    t.datetime "activation_sent_at"
    t.datetime "deleted_at"
    t.uuid     "plan_id"
    t.string   "invite_state"
    t.string   "invite_token"
    t.datetime "invite_sent_at"
    t.index ["created_at"], name: "index_accounts_on_created_at", where: "(deleted_at IS NULL)", using: :btree
    t.index ["deleted_at"], name: "index_accounts_on_deleted_at", using: :btree
    t.index ["id"], name: "index_accounts_on_id", where: "(deleted_at IS NULL)", using: :btree
    t.index ["plan_id"], name: "index_accounts_on_plan_id", where: "(deleted_at IS NULL)", using: :btree
    t.index ["slug"], name: "index_accounts_on_slug", where: "(deleted_at IS NULL)", using: :btree
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
    t.datetime "deleted_at"
    t.uuid     "account_id"
    t.index ["account_id"], name: "index_billings_on_account_id", where: "(deleted_at IS NULL)", using: :btree
    t.index ["created_at"], name: "index_billings_on_created_at", where: "(deleted_at IS NULL)", using: :btree
    t.index ["deleted_at"], name: "index_billings_on_deleted_at", using: :btree
    t.index ["id"], name: "index_billings_on_id", where: "(deleted_at IS NULL)", using: :btree
  end

  create_table "keys", id: :uuid, default: -> { "uuid_generate_v4()" }, force: :cascade do |t|
    t.string   "key"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.datetime "deleted_at"
    t.uuid     "policy_id"
    t.uuid     "account_id"
    t.index ["account_id"], name: "index_keys_on_account_id", where: "(deleted_at IS NULL)", using: :btree
    t.index ["created_at"], name: "index_keys_on_created_at", where: "(deleted_at IS NULL)", using: :btree
    t.index ["deleted_at"], name: "index_keys_on_deleted_at", using: :btree
    t.index ["id"], name: "index_keys_on_id", where: "(deleted_at IS NULL)", using: :btree
    t.index ["policy_id"], name: "index_keys_on_policy_id", where: "(deleted_at IS NULL)", using: :btree
  end

  create_table "licenses", id: :uuid, default: -> { "uuid_generate_v4()" }, force: :cascade do |t|
    t.string   "key"
    t.datetime "expiry"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.datetime "deleted_at"
    t.jsonb    "metadata"
    t.uuid     "user_id"
    t.uuid     "policy_id"
    t.uuid     "account_id"
    t.index ["account_id"], name: "index_licenses_on_account_id", where: "(deleted_at IS NULL)", using: :btree
    t.index ["created_at"], name: "index_licenses_on_created_at", where: "(deleted_at IS NULL)", using: :btree
    t.index ["deleted_at"], name: "index_licenses_on_deleted_at", using: :btree
    t.index ["id"], name: "index_licenses_on_id", where: "(deleted_at IS NULL)", using: :btree
    t.index ["policy_id"], name: "index_licenses_on_policy_id", where: "(deleted_at IS NULL)", using: :btree
    t.index ["user_id"], name: "index_licenses_on_user_id", where: "(deleted_at IS NULL)", using: :btree
  end

  create_table "machines", id: :uuid, default: -> { "uuid_generate_v4()" }, force: :cascade do |t|
    t.string   "fingerprint"
    t.string   "ip"
    t.string   "hostname"
    t.string   "platform"
    t.datetime "created_at",  null: false
    t.datetime "updated_at",  null: false
    t.string   "name"
    t.datetime "deleted_at"
    t.jsonb    "metadata"
    t.uuid     "account_id"
    t.uuid     "license_id"
    t.index ["account_id"], name: "index_machines_on_account_id", where: "(deleted_at IS NULL)", using: :btree
    t.index ["created_at"], name: "index_machines_on_created_at", where: "(deleted_at IS NULL)", using: :btree
    t.index ["deleted_at"], name: "index_machines_on_deleted_at", using: :btree
    t.index ["id"], name: "index_machines_on_id", where: "(deleted_at IS NULL)", using: :btree
    t.index ["license_id"], name: "index_machines_on_license_id", where: "(deleted_at IS NULL)", using: :btree
  end

  create_table "plans", id: :uuid, default: -> { "uuid_generate_v4()" }, force: :cascade do |t|
    t.string   "name"
    t.integer  "price"
    t.integer  "max_users"
    t.integer  "max_policies"
    t.integer  "max_licenses"
    t.datetime "created_at",   null: false
    t.datetime "updated_at",   null: false
    t.integer  "max_products"
    t.string   "plan_id"
    t.datetime "deleted_at"
    t.index ["created_at"], name: "index_plans_on_created_at", where: "(deleted_at IS NULL)", using: :btree
    t.index ["deleted_at"], name: "index_plans_on_deleted_at", using: :btree
    t.index ["id"], name: "index_plans_on_id", where: "(deleted_at IS NULL)", using: :btree
    t.index ["plan_id"], name: "index_plans_on_plan_id", where: "(deleted_at IS NULL)", using: :btree
  end

  create_table "policies", id: :uuid, default: -> { "uuid_generate_v4()" }, force: :cascade do |t|
    t.string   "name"
    t.integer  "price"
    t.integer  "duration"
    t.boolean  "strict",       default: false
    t.boolean  "recurring",    default: false
    t.boolean  "floating",     default: true
    t.boolean  "use_pool",     default: false
    t.datetime "created_at",                   null: false
    t.datetime "updated_at",                   null: false
    t.integer  "lock_version", default: 0,     null: false
    t.integer  "max_machines"
    t.boolean  "encrypted",    default: false
    t.boolean  "protected",    default: false
    t.datetime "deleted_at"
    t.jsonb    "metadata"
    t.uuid     "product_id"
    t.uuid     "account_id"
    t.index ["account_id"], name: "index_policies_on_account_id", where: "(deleted_at IS NULL)", using: :btree
    t.index ["created_at"], name: "index_policies_on_created_at", where: "(deleted_at IS NULL)", using: :btree
    t.index ["deleted_at"], name: "index_policies_on_deleted_at", using: :btree
    t.index ["id"], name: "index_policies_on_id", where: "(deleted_at IS NULL)", using: :btree
    t.index ["product_id"], name: "index_policies_on_product_id", where: "(deleted_at IS NULL)", using: :btree
  end

  create_table "products", id: :uuid, default: -> { "uuid_generate_v4()" }, force: :cascade do |t|
    t.string   "name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.datetime "deleted_at"
    t.jsonb    "platforms"
    t.jsonb    "metadata"
    t.uuid     "account_id"
    t.index ["account_id"], name: "index_products_on_account_id", where: "(deleted_at IS NULL)", using: :btree
    t.index ["created_at"], name: "index_products_on_created_at", where: "(deleted_at IS NULL)", using: :btree
    t.index ["deleted_at"], name: "index_products_on_deleted_at", using: :btree
    t.index ["id"], name: "index_products_on_id", where: "(deleted_at IS NULL)", using: :btree
  end

  create_table "receipts", id: :uuid, default: -> { "uuid_generate_v4()" }, force: :cascade do |t|
    t.string   "invoice_id"
    t.integer  "amount"
    t.boolean  "paid"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.datetime "deleted_at"
    t.uuid     "billing_id"
    t.index ["billing_id"], name: "index_receipts_on_billing_id", where: "(deleted_at IS NULL)", using: :btree
    t.index ["created_at"], name: "index_receipts_on_created_at", where: "(deleted_at IS NULL)", using: :btree
    t.index ["deleted_at"], name: "index_receipts_on_deleted_at", using: :btree
    t.index ["id"], name: "index_receipts_on_id", where: "(deleted_at IS NULL)", using: :btree
  end

  create_table "roles", id: :uuid, default: -> { "uuid_generate_v4()" }, force: :cascade do |t|
    t.string   "name"
    t.string   "resource_type"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.datetime "deleted_at"
    t.uuid     "resource_id"
    t.index ["created_at"], name: "index_roles_on_created_at", where: "(deleted_at IS NULL)", using: :btree
    t.index ["deleted_at"], name: "index_roles_on_deleted_at", using: :btree
    t.index ["id"], name: "index_roles_on_id", where: "(deleted_at IS NULL)", using: :btree
    t.index ["resource_id"], name: "index_roles_on_resource_id", where: "(deleted_at IS NULL)", using: :btree
  end

  create_table "tokens", id: :uuid, default: -> { "uuid_generate_v4()" }, force: :cascade do |t|
    t.string   "digest"
    t.string   "bearer_type"
    t.datetime "created_at",  null: false
    t.datetime "updated_at",  null: false
    t.datetime "expiry"
    t.datetime "deleted_at"
    t.uuid     "bearer_id"
    t.uuid     "account_id"
    t.index ["account_id"], name: "index_tokens_on_account_id", where: "(deleted_at IS NULL)", using: :btree
    t.index ["bearer_id"], name: "index_tokens_on_bearer_id", where: "(deleted_at IS NULL)", using: :btree
    t.index ["created_at"], name: "index_tokens_on_created_at", where: "(deleted_at IS NULL)", using: :btree
    t.index ["deleted_at"], name: "index_tokens_on_deleted_at", using: :btree
    t.index ["id"], name: "index_tokens_on_id", where: "(deleted_at IS NULL)", using: :btree
  end

  create_table "users", id: :uuid, default: -> { "uuid_generate_v4()" }, force: :cascade do |t|
    t.string   "name"
    t.string   "email"
    t.string   "password_digest"
    t.datetime "created_at",             null: false
    t.datetime "updated_at",             null: false
    t.string   "password_reset_token"
    t.datetime "password_reset_sent_at"
    t.datetime "deleted_at"
    t.jsonb    "metadata"
    t.uuid     "account_id"
    t.index ["account_id"], name: "index_users_on_account_id", where: "(deleted_at IS NULL)", using: :btree
    t.index ["created_at"], name: "index_users_on_created_at", where: "(deleted_at IS NULL)", using: :btree
    t.index ["deleted_at"], name: "index_users_on_deleted_at", using: :btree
    t.index ["id"], name: "index_users_on_id", where: "(deleted_at IS NULL)", using: :btree
  end

  create_table "webhook_endpoints", id: :uuid, default: -> { "uuid_generate_v4()" }, force: :cascade do |t|
    t.string   "url"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.datetime "deleted_at"
    t.uuid     "account_id"
    t.index ["account_id"], name: "index_webhook_endpoints_on_account_id", where: "(deleted_at IS NULL)", using: :btree
    t.index ["created_at"], name: "index_webhook_endpoints_on_created_at", where: "(deleted_at IS NULL)", using: :btree
    t.index ["deleted_at"], name: "index_webhook_endpoints_on_deleted_at", using: :btree
    t.index ["id"], name: "index_webhook_endpoints_on_id", where: "(deleted_at IS NULL)", using: :btree
  end

  create_table "webhook_events", id: :uuid, default: -> { "uuid_generate_v4()" }, force: :cascade do |t|
    t.text     "payload"
    t.string   "jid"
    t.datetime "created_at",        null: false
    t.datetime "updated_at",        null: false
    t.string   "endpoint"
    t.datetime "deleted_at"
    t.uuid     "account_id"
    t.string   "idempotency_token"
    t.index ["account_id"], name: "index_webhook_events_on_account_id", where: "(deleted_at IS NULL)", using: :btree
    t.index ["created_at"], name: "index_webhook_events_on_created_at", where: "(deleted_at IS NULL)", using: :btree
    t.index ["deleted_at"], name: "index_webhook_events_on_deleted_at", using: :btree
    t.index ["id"], name: "index_webhook_events_on_id", where: "(deleted_at IS NULL)", using: :btree
    t.index ["jid"], name: "index_webhook_events_on_jid", where: "(deleted_at IS NULL)", using: :btree
  end

end
