class AddCodeToProducts < ActiveRecord::Migration[7.0]
  def change
    add_column :products, :code, :string, null: true

    add_index :products, %i[account_id code], unique: true
  end
end
