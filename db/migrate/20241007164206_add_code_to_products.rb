class AddCodeToProducts < ActiveRecord::Migration[7.1]
  disable_ddl_transaction!

  def change
    add_column :products, :code, :string, null: true, if_not_exists: true

    add_index :products, %i[account_id code], algorithm: :concurrently, unique: true
    add_index :products, :code, algorithm: :concurrently
  end
end
