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

ActiveRecord::Schema.define(version: 20160625172108) do

  create_table "accounts", force: :cascade do |t|
    t.string   "name"
    t.string   "subdomain"
    t.datetime "created_at",                            null: false
    t.datetime "updated_at",                            null: false
    t.integer  "plan_id"
    t.string   "status",             default: "active"
    t.string   "activation_token"
    t.datetime "activation_sent_at"
    t.boolean  "activated",          default: false
  end

  create_table "billings", force: :cascade do |t|
    t.string   "external_customer_id"
    t.string   "external_status"
    t.datetime "created_at",                         null: false
    t.datetime "updated_at",                         null: false
    t.integer  "customer_id"
    t.string   "customer_type"
    t.string   "external_subscription_id"
    t.datetime "external_subscription_period_start"
    t.datetime "external_subscription_period_end"
  end

  create_table "licenses", force: :cascade do |t|
    t.string   "key"
    t.datetime "expiry"
    t.integer  "user_id"
    t.datetime "created_at",      null: false
    t.datetime "updated_at",      null: false
    t.integer  "policy_id"
    t.string   "active_machines"
    t.integer  "account_id"
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
    t.integer  "user_id"
  end

  create_table "plans", force: :cascade do |t|
    t.string   "name"
    t.integer  "price"
    t.integer  "max_users"
    t.integer  "max_policies"
    t.integer  "max_licenses"
    t.datetime "created_at",       null: false
    t.datetime "updated_at",       null: false
    t.integer  "max_products"
    t.string   "external_plan_id"
  end

  create_table "policies", force: :cascade do |t|
    t.string   "name"
    t.integer  "price"
    t.integer  "duration"
    t.boolean  "strict",          default: false
    t.boolean  "recurring",       default: false
    t.boolean  "floating",        default: true
    t.boolean  "use_pool",        default: false
    t.datetime "created_at",                      null: false
    t.datetime "updated_at",                      null: false
    t.string   "pool"
    t.integer  "lock_version",    default: 0,     null: false
    t.integer  "product_id"
    t.integer  "account_id"
    t.integer  "max_activations"
  end

  create_table "products", force: :cascade do |t|
    t.string   "name"
    t.string   "platforms"
    t.integer  "account_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "products_users", force: :cascade do |t|
    t.integer "product_id"
    t.integer "user_id"
    t.index ["product_id"], name: "index_products_users_on_product_id"
    t.index ["user_id", "product_id"], name: "index_products_users_on_user_id_and_product_id", unique: true
    t.index ["user_id"], name: "index_products_users_on_user_id"
  end

  create_table "users", force: :cascade do |t|
    t.string   "name"
    t.string   "email"
    t.string   "password_digest"
    t.string   "role",                   default: "user"
    t.integer  "account_id"
    t.datetime "created_at",                              null: false
    t.datetime "updated_at",                              null: false
    t.string   "auth_token"
    t.string   "reset_auth_token"
    t.string   "password_reset_token"
    t.datetime "password_reset_sent_at"
    t.string   "meta"
  end

end
