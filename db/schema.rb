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

ActiveRecord::Schema.define(version: 20161128224903) do

  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "accounts", force: :cascade do |t|
    t.string   "company"
    t.datetime "created_at",         null: false
    t.datetime "updated_at",         null: false
    t.integer  "plan_id"
    t.string   "activation_token"
    t.datetime "activation_sent_at"
    t.datetime "deleted_at"
    t.string   "name"
    t.index ["deleted_at"], name: "index_accounts_on_deleted_at", using: :btree
    t.index ["name"], name: "index_accounts_on_name", using: :btree
  end

  create_table "billings", force: :cascade do |t|
    t.string   "customer_id"
    t.string   "subscription_status"
    t.datetime "created_at",                null: false
    t.datetime "updated_at",                null: false
    t.integer  "account_id"
    t.string   "subscription_id"
    t.datetime "subscription_period_start"
    t.datetime "subscription_period_end"
    t.datetime "card_expiry"
    t.string   "card_brand"
    t.string   "card_last4"
    t.string   "state"
    t.datetime "deleted_at"
    t.index ["customer_id"], name: "index_billings_on_customer_id", using: :btree
    t.index ["deleted_at"], name: "index_billings_on_deleted_at", using: :btree
    t.index ["subscription_id"], name: "index_billings_on_subscription_id", using: :btree
  end

  create_table "keys", force: :cascade do |t|
    t.string   "key"
    t.integer  "policy_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer  "account_id"
    t.datetime "deleted_at"
    t.index ["account_id"], name: "index_keys_on_account_id", using: :btree
    t.index ["deleted_at"], name: "index_keys_on_deleted_at", using: :btree
    t.index ["policy_id"], name: "index_keys_on_policy_id", using: :btree
  end

  create_table "licenses", force: :cascade do |t|
    t.string   "key"
    t.datetime "expiry"
    t.integer  "user_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer  "policy_id"
    t.integer  "account_id"
    t.datetime "deleted_at"
    t.json     "metadata"
    t.index ["account_id"], name: "index_licenses_on_account_id", using: :btree
    t.index ["deleted_at"], name: "index_licenses_on_deleted_at", using: :btree
    t.index ["key"], name: "index_licenses_on_key", using: :btree
    t.index ["policy_id"], name: "index_licenses_on_policy_id", using: :btree
    t.index ["user_id"], name: "index_licenses_on_user_id", using: :btree
  end

  create_table "machines", force: :cascade do |t|
    t.string   "fingerprint"
    t.string   "ip"
    t.string   "hostname"
    t.string   "platform"
    t.integer  "account_id"
    t.integer  "license_id"
    t.datetime "created_at",  null: false
    t.datetime "updated_at",  null: false
    t.string   "name"
    t.datetime "deleted_at"
    t.json     "metadata"
    t.index ["account_id"], name: "index_machines_on_account_id", using: :btree
    t.index ["deleted_at"], name: "index_machines_on_deleted_at", using: :btree
    t.index ["fingerprint"], name: "index_machines_on_fingerprint", using: :btree
    t.index ["license_id"], name: "index_machines_on_license_id", using: :btree
  end

  create_table "plans", force: :cascade do |t|
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
    t.index ["deleted_at"], name: "index_plans_on_deleted_at", using: :btree
    t.index ["plan_id"], name: "index_plans_on_plan_id", using: :btree
  end

  create_table "policies", force: :cascade do |t|
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
    t.integer  "product_id"
    t.integer  "account_id"
    t.integer  "max_machines"
    t.boolean  "encrypted",    default: false
    t.boolean  "protected",    default: false
    t.datetime "deleted_at"
    t.json     "metadata"
    t.index ["account_id"], name: "index_policies_on_account_id", using: :btree
    t.index ["deleted_at"], name: "index_policies_on_deleted_at", using: :btree
    t.index ["product_id"], name: "index_policies_on_product_id", using: :btree
  end

  create_table "products", force: :cascade do |t|
    t.string   "name"
    t.integer  "account_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.datetime "deleted_at"
    t.json     "platforms"
    t.json     "metadata"
    t.index ["account_id"], name: "index_products_on_account_id", using: :btree
    t.index ["deleted_at"], name: "index_products_on_deleted_at", using: :btree
  end

  create_table "receipts", force: :cascade do |t|
    t.integer  "billing_id"
    t.string   "invoice_id"
    t.integer  "amount"
    t.boolean  "paid"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.datetime "deleted_at"
    t.index ["deleted_at"], name: "index_receipts_on_deleted_at", using: :btree
  end

  create_table "roles", force: :cascade do |t|
    t.string   "name"
    t.string   "resource_type"
    t.integer  "resource_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.datetime "deleted_at"
    t.index ["deleted_at"], name: "index_roles_on_deleted_at", using: :btree
    t.index ["name", "resource_type", "resource_id"], name: "index_roles_on_name_and_resource_type_and_resource_id", using: :btree
    t.index ["name"], name: "index_roles_on_name", using: :btree
  end

  create_table "tokens", force: :cascade do |t|
    t.string   "digest"
    t.integer  "bearer_id"
    t.string   "bearer_type"
    t.datetime "created_at",  null: false
    t.datetime "updated_at",  null: false
    t.integer  "account_id"
    t.datetime "expiry"
    t.datetime "deleted_at"
    t.index ["account_id"], name: "index_tokens_on_account_id", using: :btree
    t.index ["bearer_id", "bearer_type"], name: "index_tokens_on_bearer_id_and_bearer_type", using: :btree
    t.index ["deleted_at"], name: "index_tokens_on_deleted_at", using: :btree
  end

  create_table "users", force: :cascade do |t|
    t.string   "name"
    t.string   "email"
    t.string   "password_digest"
    t.integer  "account_id"
    t.datetime "created_at",             null: false
    t.datetime "updated_at",             null: false
    t.string   "password_reset_token"
    t.datetime "password_reset_sent_at"
    t.datetime "deleted_at"
    t.json     "metadata"
    t.index ["account_id"], name: "index_users_on_account_id", using: :btree
    t.index ["deleted_at"], name: "index_users_on_deleted_at", using: :btree
    t.index ["email"], name: "index_users_on_email", using: :btree
    t.index ["password_reset_token"], name: "index_users_on_password_reset_token", using: :btree
  end

  create_table "webhook_endpoints", force: :cascade do |t|
    t.integer  "account_id"
    t.string   "url"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.datetime "deleted_at"
    t.index ["account_id"], name: "index_webhook_endpoints_on_account_id", using: :btree
    t.index ["deleted_at"], name: "index_webhook_endpoints_on_deleted_at", using: :btree
  end

  create_table "webhook_events", force: :cascade do |t|
    t.integer  "account_id"
    t.text     "payload"
    t.string   "jid"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string   "endpoint"
    t.datetime "deleted_at"
    t.index ["account_id"], name: "index_webhook_events_on_account_id", using: :btree
    t.index ["deleted_at"], name: "index_webhook_events_on_deleted_at", using: :btree
    t.index ["jid"], name: "index_webhook_events_on_jid", using: :btree
  end

end
