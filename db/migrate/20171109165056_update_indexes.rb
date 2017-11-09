class UpdateIndexes < ActiveRecord::Migration[5.0]
  def change
    remove_index :accounts, [:created_at, :id, :slug]
    remove_index :accounts, [:created_at, :plan_id]
    remove_index :accounts, [:created_at, :slug]
    remove_index :accounts, :slug
    remove_index :accounts, :id
    add_index :accounts, [:slug, :created_at], unique: true
    add_index :accounts, [:id, :created_at], unique: true
    add_index :accounts, [:plan_id, :created_at]
    add_index :accounts, :slug, unique: true

    remove_index :billings, [:created_at, :account_id]
    remove_index :billings, [:created_at, :customer_id]
    remove_index :billings, [:created_at, :id]
    remove_index :billings, [:created_at, :subscription_id]
    remove_index :billings, :id
    add_index :billings, [:account_id, :created_at]
    add_index :billings, [:customer_id, :created_at]
    add_index :billings, [:id, :created_at], unique: true
    add_index :billings, [:subscription_id, :created_at]

    remove_index :keys, [:created_at, :account_id]
    remove_index :keys, [:created_at, :id]
    remove_index :keys, [:created_at, :policy_id]
    remove_index :keys, :id
    add_index :keys, [:id, :created_at, :account_id], unique: true
    add_index :keys, [:account_id, :created_at]
    add_index :keys, [:policy_id, :created_at]

    remove_index :licenses, [:created_at, :account_id]
    remove_index :licenses, [:created_at, :id]
    remove_index :licenses, [:created_at, :policy_id]
    remove_index :licenses, [:created_at, :user_id]
    remove_index :licenses, :id
    add_index :licenses, [:account_id, :created_at]
    add_index :licenses, [:id, :created_at, :account_id], unique: true
    add_index :licenses, [:policy_id, :created_at]
    add_index :licenses, [:user_id, :created_at]

    remove_index :machines, [:created_at, :account_id]
    remove_index :machines, [:created_at, :id]
    remove_index :machines, [:created_at, :license_id]
    remove_index :machines, :id
    add_index :machines, [:account_id, :created_at]
    add_index :machines, [:id, :created_at, :account_id], unique: true
    add_index :machines, [:license_id, :created_at]

    remove_index :metrics, [:created_at, :account_id]
    remove_index :metrics, [:created_at, :id]
    add_index :metrics, [:account_id, :created_at]
    add_index :metrics, [:id, :created_at], unique: true

    remove_index :plans, [:created_at, :id]
    remove_index :plans, [:created_at, :plan_id]
    remove_index :plans, :id
    add_index :plans, [:id, :created_at], unique: true
    add_index :plans, [:plan_id, :created_at]

    remove_index :policies, [:created_at, :account_id]
    remove_index :policies, [:created_at, :id]
    remove_index :policies, [:created_at, :product_id]
    remove_index :policies, :id
    add_index :policies, [:account_id, :created_at]
    add_index :policies, [:id, :created_at, :account_id], unique: true
    add_index :policies, [:product_id, :created_at]

    remove_index :products, [:created_at, :account_id]
    remove_index :products, [:created_at, :id]
    remove_index :products, :id
    add_index :products, [:account_id, :created_at]
    add_index :products, [:id, :created_at, :account_id], unique: true

    remove_index :receipts, [:created_at, :billing_id]
    remove_index :receipts, [:created_at, :id]
    remove_index :receipts, :id
    add_index :receipts, [:billing_id, :created_at]
    add_index :receipts, [:id, :created_at], unique: true

    remove_index :roles, [:created_at, :id]
    remove_index :roles, [:created_at, :name]
    remove_index :roles, [:created_at, :resource_id, :resource_type]
    remove_index :roles, :id
    add_index :roles, [:id, :created_at], unique: true
    add_index :roles, [:name, :created_at]
    add_index :roles, [:resource_id, :resource_type, :created_at]

    remove_index :tokens, [:created_at, :account_id]
    remove_index :tokens, [:created_at, :bearer_id, :bearer_type]
    remove_index :tokens, [:created_at, :id]
    remove_index :tokens, :id
    add_index :tokens, [:account_id, :created_at]
    add_index :tokens, [:id, :created_at, :account_id], unique: true
    add_index :tokens, [:bearer_id, :bearer_type, :created_at]

    remove_index :users, [:created_at, :account_id, :email]
    remove_index :users, [:created_at, :account_id]
    remove_index :users, [:created_at, :id]
    remove_index :users, :id
    add_index :users, [:email, :account_id, :created_at]
    add_index :users, [:account_id, :created_at]
    add_index :users, [:id, :created_at, :account_id], unique: true

    remove_index :webhook_endpoints, [:created_at, :account_id]
    remove_index :webhook_endpoints, [:created_at, :id]
    remove_index :webhook_endpoints, :id
    add_index :webhook_endpoints, [:account_id, :created_at]
    add_index :webhook_endpoints, [:id, :created_at, :account_id], unique: true

    remove_index :webhook_events, [:created_at, :account_id]
    remove_index :webhook_events, [:created_at, :id]
    remove_index :webhook_events, [:created_at, :jid]
    remove_index :webhook_events, :id
    add_index :webhook_events, [:account_id, :created_at]
    add_index :webhook_events, [:id, :created_at, :account_id], unique: true
    add_index :webhook_events, [:jid, :created_at, :account_id]
  end
end
