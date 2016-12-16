class AddAssociationIndices < ActiveRecord::Migration[5.0]
  def up
    add_index :accounts, :plan_id
    add_index :billings, :account_id
    add_index :keys, :policy_id
    add_index :keys, :account_id
    add_index :licenses, :user_id
    add_index :licenses, :policy_id
    add_index :licenses, :account_id
    add_index :machines, :account_id
    add_index :machines, :license_id
    add_index :policies, :product_id
    add_index :policies, :account_id
    add_index :products, :account_id
    add_index :receipts, :billing_id
    add_index :roles, :resource_id
    add_index :tokens, :bearer_id
    add_index :tokens, :account_id
    add_index :users, :account_id
    add_index :webhook_endpoints, :account_id
    add_index :webhook_events, :account_id
  end
end
