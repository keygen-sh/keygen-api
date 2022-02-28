class AddIndexToBannedAtForUsers < ActiveRecord::Migration[6.1]
  disable_ddl_transaction!

  def change
    add_index :users, :banned_at, algorithm: :concurrently
  end
end
