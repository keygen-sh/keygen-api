class AddUniqueIndexToEmailForUsers < ActiveRecord::Migration[6.1]
  disable_ddl_transaction!

  def change
    remove_index :users, [:email, :account_id, :created_at], if_exists: true

    add_index :users, [:email, :account_id], unique: true, algorithm: :concurrently
  end
end
