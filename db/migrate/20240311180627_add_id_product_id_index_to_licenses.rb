class AddIdProductIdIndexToLicenses < ActiveRecord::Migration[7.1]
  disable_ddl_transaction!

  def change
    add_index :licenses, %i[id product_id account_id], algorithm: :concurrently
  end
end
