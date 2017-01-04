class RemoveParanoia < ActiveRecord::Migration[5.0]
  def change
    # create_table "accounts", id: :uuid, default: -> { "uuid_generate_v4()" }, force: :cascade do |t|
    # t.index ["created_at"], name: "index_accounts_on_created_at", where: "(deleted_at IS NULL)", using: :btree
    # t.index ["deleted_at"], name: "index_accounts_on_deleted_at", using: :btree
    # t.index ["id"], name: "index_accounts_on_id", where: "(deleted_at IS NULL)", using: :btree
    # t.index ["plan_id"], name: "index_accounts_on_plan_id", where: "(deleted_at IS NULL)", using: :btree
    # t.index ["slug"], name: "index_accounts_on_slug", where: "(deleted_at IS NULL)", using: :btree

    remove_index :accounts, [:created_at]
    remove_index :accounts, [:deleted_at]
    remove_index :accounts, [:id]
    remove_index :accounts, [:plan_id]
    remove_index :accounts, [:slug]
    add_index :accounts, [:plan_id]
    add_index :accounts, [:slug]

    # create_table "billings", id: :uuid, default: -> { "uuid_generate_v4()" }, force: :cascade do |t|
    # t.index ["account_id"], name: "index_billings_on_account_id", where: "(deleted_at IS NULL)", using: :btree
    # t.index ["created_at"], name: "index_billings_on_created_at", where: "(deleted_at IS NULL)", using: :btree
    # t.index ["deleted_at"], name: "index_billings_on_deleted_at", using: :btree
    # t.index ["id"], name: "index_billings_on_id", where: "(deleted_at IS NULL)", using: :btree

    remove_index :billings, [:account_id]
    remove_index :billings, [:created_at]
    remove_index :billings, [:deleted_at]
    remove_index :billings, [:id]
    add_index :billings, [:account_id]

    # create_table "keys", id: :uuid, default: -> { "uuid_generate_v4()" }, force: :cascade do |t|
    # t.index ["account_id"], name: "index_keys_on_account_id", where: "(deleted_at IS NULL)", using: :btree
    # t.index ["created_at"], name: "index_keys_on_created_at", where: "(deleted_at IS NULL)", using: :btree
    # t.index ["deleted_at"], name: "index_keys_on_deleted_at", using: :btree
    # t.index ["id"], name: "index_keys_on_id", where: "(deleted_at IS NULL)", using: :btree
    # t.index ["policy_id"], name: "index_keys_on_policy_id", where: "(deleted_at IS NULL)", using: :btree

    remove_index :keys, [:account_id]
    remove_index :keys, [:created_at]
    remove_index :keys, [:deleted_at]
    remove_index :keys, [:id]
    remove_index :keys, [:policy_id]
    add_index :keys, [:account_id]
    add_index :keys, [:policy_id]

    # create_table "licenses", id: :uuid, default: -> { "uuid_generate_v4()" }, force: :cascade do |t|
    # t.index ["account_id"], name: "index_licenses_on_account_id", where: "(deleted_at IS NULL)", using: :btree
    # t.index ["created_at"], name: "index_licenses_on_created_at", where: "(deleted_at IS NULL)", using: :btree
    # t.index ["deleted_at"], name: "index_licenses_on_deleted_at", using: :btree
    # t.index ["id"], name: "index_licenses_on_id", where: "(deleted_at IS NULL)", using: :btree
    # t.index ["policy_id"], name: "index_licenses_on_policy_id", where: "(deleted_at IS NULL)", using: :btree
    # t.index ["user_id"], name: "index_licenses_on_user_id", where: "(deleted_at IS NULL)", using: :btree

    remove_index :licenses, [:account_id]
    remove_index :licenses, [:created_at]
    remove_index :licenses, [:deleted_at]
    remove_index :licenses, [:id]
    remove_index :licenses, [:policy_id]
    remove_index :licenses, [:user_id]
    add_index :licenses, [:account_id]
    add_index :licenses, [:policy_id]
    add_index :licenses, [:user_id]

    # create_table "machines", id: :uuid, default: -> { "uuid_generate_v4()" }, force: :cascade do |t|
    # t.index ["account_id"], name: "index_machines_on_account_id", where: "(deleted_at IS NULL)", using: :btree
    # t.index ["created_at"], name: "index_machines_on_created_at", where: "(deleted_at IS NULL)", using: :btree
    # t.index ["deleted_at"], name: "index_machines_on_deleted_at", using: :btree
    # t.index ["id"], name: "index_machines_on_id", where: "(deleted_at IS NULL)", using: :btree
    # t.index ["license_id"], name: "index_machines_on_license_id", where: "(deleted_at IS NULL)", using: :btree

    remove_index :machines, [:account_id]
    remove_index :machines, [:created_at]
    remove_index :machines, [:deleted_at]
    remove_index :machines, [:id]
    remove_index :machines, [:license_id]
    add_index :machines, [:account_id]
    add_index :machines, [:license_id]

    # create_table "plans", id: :uuid, default: -> { "uuid_generate_v4()" }, force: :cascade do |t|
    # t.index ["created_at"], name: "index_plans_on_created_at", where: "(deleted_at IS NULL)", using: :btree
    # t.index ["deleted_at"], name: "index_plans_on_deleted_at", using: :btree
    # t.index ["id"], name: "index_plans_on_id", where: "(deleted_at IS NULL)", using: :btree
    # t.index ["plan_id"], name: "index_plans_on_plan_id", where: "(deleted_at IS NULL)", using: :btree

    remove_index :plans, [:created_at]
    remove_index :plans, [:deleted_at]
    remove_index :plans, [:id]
    remove_index :plans, [:plan_id]
    add_index :plans, [:plan_id]

    # create_table "policies", id: :uuid, default: -> { "uuid_generate_v4()" }, force: :cascade do |t|
    # t.index ["account_id"], name: "index_policies_on_account_id", where: "(deleted_at IS NULL)", using: :btree
    # t.index ["created_at"], name: "index_policies_on_created_at", where: "(deleted_at IS NULL)", using: :btree
    # t.index ["deleted_at"], name: "index_policies_on_deleted_at", using: :btree
    # t.index ["id"], name: "index_policies_on_id", where: "(deleted_at IS NULL)", using: :btree
    # t.index ["product_id"], name: "index_policies_on_product_id", where: "(deleted_at IS NULL)", using: :btree

    remove_index :policies, [:account_id]
    remove_index :policies, [:created_at]
    remove_index :policies, [:deleted_at]
    remove_index :policies, [:id]
    remove_index :policies, [:product_id]
    add_index :policies, [:account_id]
    add_index :policies, [:product_id]

    # create_table "products", id: :uuid, default: -> { "uuid_generate_v4()" }, force: :cascade do |t|
    # t.index ["account_id"], name: "index_products_on_account_id", where: "(deleted_at IS NULL)", using: :btree
    # t.index ["created_at"], name: "index_products_on_created_at", where: "(deleted_at IS NULL)", using: :btree
    # t.index ["deleted_at"], name: "index_products_on_deleted_at", using: :btree
    # t.index ["id"], name: "index_products_on_id", where: "(deleted_at IS NULL)", using: :btree

    remove_index :products, [:account_id]
    remove_index :products, [:created_at]
    remove_index :products, [:deleted_at]
    remove_index :products, [:id]
    add_index :products, [:account_id]

    # create_table "receipts", id: :uuid, default: -> { "uuid_generate_v4()" }, force: :cascade do |t|
    # t.index ["billing_id"], name: "index_receipts_on_billing_id", where: "(deleted_at IS NULL)", using: :btree
    # t.index ["created_at"], name: "index_receipts_on_created_at", where: "(deleted_at IS NULL)", using: :btree
    # t.index ["deleted_at"], name: "index_receipts_on_deleted_at", using: :btree
    # t.index ["id"], name: "index_receipts_on_id", where: "(deleted_at IS NULL)", using: :btree

    remove_index :receipts, [:billing_id]
    remove_index :receipts, [:created_at]
    remove_index :receipts, [:deleted_at]
    remove_index :receipts, [:id]
    add_index :receipts, [:billing_id]

    # create_table "roles", id: :uuid, default: -> { "uuid_generate_v4()" }, force: :cascade do |t|
    # t.index ["created_at"], name: "index_roles_on_created_at", where: "(deleted_at IS NULL)", using: :btree
    # t.index ["deleted_at"], name: "index_roles_on_deleted_at", using: :btree
    # t.index ["id"], name: "index_roles_on_id", where: "(deleted_at IS NULL)", using: :btree
    # t.index ["resource_id"], name: "index_roles_on_resource_id", where: "(deleted_at IS NULL)", using: :btree

    remove_index :roles, [:resource_id]
    remove_index :roles, [:created_at]
    remove_index :roles, [:deleted_at]
    remove_index :roles, [:id]
    add_index :roles, [:resource_id, :resource_type]

    # create_table "tokens", id: :uuid, default: -> { "uuid_generate_v4()" }, force: :cascade do |t|
    # t.index ["account_id"], name: "index_tokens_on_account_id", where: "(deleted_at IS NULL)", using: :btree
    # t.index ["bearer_id"], name: "index_tokens_on_bearer_id", where: "(deleted_at IS NULL)", using: :btree
    # t.index ["created_at"], name: "index_tokens_on_created_at", where: "(deleted_at IS NULL)", using: :btree
    # t.index ["deleted_at"], name: "index_tokens_on_deleted_at", using: :btree
    # t.index ["id"], name: "index_tokens_on_id", where: "(deleted_at IS NULL)", using: :btree

    remove_index :tokens, [:account_id]
    remove_index :tokens, [:bearer_id]
    remove_index :tokens, [:created_at]
    remove_index :tokens, [:deleted_at]
    remove_index :tokens, [:id]
    add_index :tokens, [:account_id]
    add_index :tokens, [:bearer_id, :bearer_type]

    # create_table "users", id: :uuid, default: -> { "uuid_generate_v4()" }, force: :cascade do |t|
    # t.index ["account_id"], name: "index_users_on_account_id", where: "(deleted_at IS NULL)", using: :btree
    # t.index ["created_at"], name: "index_users_on_created_at", where: "(deleted_at IS NULL)", using: :btree
    # t.index ["deleted_at"], name: "index_users_on_deleted_at", using: :btree
    # t.index ["id"], name: "index_users_on_id", where: "(deleted_at IS NULL)", using: :btree

    remove_index :users, [:account_id]
    remove_index :users, [:created_at]
    remove_index :users, [:deleted_at]
    remove_index :users, [:id]
    add_index :users, [:account_id]

    # create_table "webhook_endpoints", id: :uuid, default: -> { "uuid_generate_v4()" }, force: :cascade do |t|
    # t.index ["account_id"], name: "index_webhook_endpoints_on_account_id", where: "(deleted_at IS NULL)", using: :btree
    # t.index ["created_at"], name: "index_webhook_endpoints_on_created_at", where: "(deleted_at IS NULL)", using: :btree
    # t.index ["deleted_at"], name: "index_webhook_endpoints_on_deleted_at", using: :btree
    # t.index ["id"], name: "index_webhook_endpoints_on_id", where: "(deleted_at IS NULL)", using: :btree

    remove_index :webhook_endpoints, [:account_id]
    remove_index :webhook_endpoints, [:created_at]
    remove_index :webhook_endpoints, [:deleted_at]
    remove_index :webhook_endpoints, [:id]
    add_index :webhook_endpoints, [:account_id]

    # create_table "webhook_events", id: :uuid, default: -> { "uuid_generate_v4()" }, force: :cascade do |t|
    # t.index ["account_id"], name: "index_webhook_events_on_account_id", where: "(deleted_at IS NULL)", using: :btree
    # t.index ["created_at"], name: "index_webhook_events_on_created_at", where: "(deleted_at IS NULL)", using: :btree
    # t.index ["deleted_at"], name: "index_webhook_events_on_deleted_at", using: :btree
    # t.index ["id"], name: "index_webhook_events_on_id", where: "(deleted_at IS NULL)", using: :btree
    # t.index ["jid"], name: "index_webhook_events_on_jid", where: "(deleted_at IS NULL)", using: :btree

    remove_index :webhook_events, [:account_id]
    remove_index :webhook_events, [:created_at]
    remove_index :webhook_events, [:deleted_at]
    remove_index :webhook_events, [:id]
    remove_index :webhook_events, [:jid]
    add_index :webhook_events, [:account_id]
    add_index :webhook_events, [:jid]
  end
end
