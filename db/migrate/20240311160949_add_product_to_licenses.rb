class AddProductToLicenses < ActiveRecord::Migration[7.1]
  disable_ddl_transaction!

  def change
    add_column :licenses, :product_id, :uuid, null: true, if_not_exists: true

    add_index :licenses, :product_id, algorithm: :concurrently, if_not_exists: true
  end
end
