class RemoveParanoia < ActiveRecord::Migration[5.0]
  def change
    tables = [
      :accounts,
      :billings,
      :keys,
      :licenses,
      :machines,
      :plans,
      :policies,
      :products,
      :receipts,
      :roles,
      :tokens,
      :users,
      :webhook_endpoints,
      :webhook_events
    ]

    remove_index :accounts, [:created_at]
    remove_index :accounts, [:deleted_at]
    remove_index :accounts, [:id]
    remove_index :accounts, [:plan_id]
    remove_index :accounts, [:slug]
    add_index :accounts, [:created_at, :id, :slug], unique: true
    add_index :accounts, [:created_at, :plan_id]

    remove_index :billings, [:account_id]
    remove_index :billings, [:created_at]
    remove_index :billings, [:deleted_at]
    remove_index :billings, [:id]
    add_index :billings, [:created_at, :id], unique: true
    add_index :billings, [:created_at, :account_id]
    add_index :billings, [:created_at, :customer_id]
    add_index :billings, [:created_at, :subscription_id]

    remove_index :keys, [:account_id]
    remove_index :keys, [:created_at]
    remove_index :keys, [:deleted_at]
    remove_index :keys, [:id]
    remove_index :keys, [:policy_id]
    add_index :keys, [:created_at, :id], unique: true
    add_index :keys, [:created_at, :account_id]
    add_index :keys, [:created_at, :policy_id]

    remove_index :licenses, [:account_id]
    remove_index :licenses, [:created_at]
    remove_index :licenses, [:deleted_at]
    remove_index :licenses, [:id]
    remove_index :licenses, [:policy_id]
    remove_index :licenses, [:user_id]
    add_index :licenses, [:created_at, :id], unique: true
    add_index :licenses, [:created_at, :account_id]
    add_index :licenses, [:created_at, :policy_id]
    add_index :licenses, [:created_at, :user_id]

    remove_index :machines, [:account_id]
    remove_index :machines, [:created_at]
    remove_index :machines, [:deleted_at]
    remove_index :machines, [:id]
    remove_index :machines, [:license_id]
    add_index :machines, [:created_at, :id], unique: true
    add_index :machines, [:created_at, :account_id]
    add_index :machines, [:created_at, :license_id]

    remove_index :plans, [:created_at]
    remove_index :plans, [:deleted_at]
    remove_index :plans, [:id]
    remove_index :plans, [:plan_id]
    add_index :plans, [:created_at, :id], unique: true
    add_index :plans, [:created_at, :plan_id]

    remove_index :policies, [:account_id]
    remove_index :policies, [:created_at]
    remove_index :policies, [:deleted_at]
    remove_index :policies, [:id]
    remove_index :policies, [:product_id]
    add_index :policies, [:created_at, :id], unique: true
    add_index :policies, [:created_at, :account_id]
    add_index :policies, [:created_at, :product_id]

    remove_index :products, [:account_id]
    remove_index :products, [:created_at]
    remove_index :products, [:deleted_at]
    remove_index :products, [:id]
    add_index :products, [:created_at, :id], unique: true
    add_index :products, [:created_at, :account_id]

    remove_index :receipts, [:billing_id]
    remove_index :receipts, [:created_at]
    remove_index :receipts, [:deleted_at]
    remove_index :receipts, [:id]
    add_index :receipts, [:created_at, :id], unique: true
    add_index :receipts, [:created_at, :billing_id]

    remove_index :roles, [:resource_id]
    remove_index :roles, [:created_at]
    remove_index :roles, [:deleted_at]
    remove_index :roles, [:id]
    add_index :roles, [:created_at, :id], unique: true
    add_index :roles, [:created_at, :resource_id, :resource_type]
    add_index :roles, [:created_at, :name]

    remove_index :tokens, [:account_id]
    remove_index :tokens, [:bearer_id]
    remove_index :tokens, [:created_at]
    remove_index :tokens, [:deleted_at]
    remove_index :tokens, [:id]
    add_index :tokens, [:created_at, :id], unique: true
    add_index :tokens, [:created_at, :account_id]
    add_index :tokens, [:created_at, :bearer_id, :bearer_type]

    remove_index :users, [:account_id]
    remove_index :users, [:created_at]
    remove_index :users, [:deleted_at]
    remove_index :users, [:id]
    add_index :users, [:created_at, :id], unique: true
    add_index :users, [:created_at, :account_id]
    add_index :users, [:created_at, :account_id, :email]

    remove_index :webhook_endpoints, [:account_id]
    remove_index :webhook_endpoints, [:created_at]
    remove_index :webhook_endpoints, [:deleted_at]
    remove_index :webhook_endpoints, [:id]
    add_index :webhook_endpoints, [:created_at, :id], unique: true
    add_index :webhook_endpoints, [:created_at, :account_id]

    remove_index :webhook_events, [:account_id]
    remove_index :webhook_events, [:created_at]
    remove_index :webhook_events, [:deleted_at]
    remove_index :webhook_events, [:id]
    remove_index :webhook_events, [:jid]
    add_index :webhook_events, [:created_at, :id], unique: true
    add_index :webhook_events, [:created_at, :account_id]
    add_index :webhook_events, [:created_at, :jid]

    tables.each do |table|
      remove_column table, :deleted_at, :datetime
    end
  end
end
