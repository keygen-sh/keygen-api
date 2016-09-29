class AddIndicesToTables < ActiveRecord::Migration[5.0]
  def change
    add_index :billings, [:customer_id, :customer_type]
    add_index :billings, :external_customer_id
    add_index :billings, :external_subscription_id

    add_index :accounts, :subdomain

    add_index :keys, :policy_id
    add_index :keys, :account_id

    add_index :licenses, :account_id
    add_index :licenses, :policy_id

    add_index :machines, :user_id
    add_index :machines, :license_id
    add_index :machines, :account_id

    add_index :plans, :external_plan_id

    add_index :policies, :account_id
    add_index :policies, :product_id

    add_index :products, :account_id

    add_index :tokens, [:bearer_id, :bearer_type]
    add_index :tokens, :auth_token
    add_index :tokens, :reset_token
    add_index :tokens, :account_id

    add_index :users, :account_id
    add_index :users, :email
    add_index :users, :password_reset_token
  end
end
