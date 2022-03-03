class AddIndexToGroupIdForUsers < ActiveRecord::Migration[6.1]
  disable_ddl_transaction!

  def change
    add_index :users, :group_id, algorithm: :concurrently
  end
end
