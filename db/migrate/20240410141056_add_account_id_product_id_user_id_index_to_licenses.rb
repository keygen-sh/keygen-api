class AddAccountIdProductIdUserIdIndexToLicenses < ActiveRecord::Migration[7.1]
  disable_ddl_transaction!

  def change
    add_index :licenses, %i[account_id product_id user_id], algorithm: :concurrently, if_not_exists: true
  end
end
