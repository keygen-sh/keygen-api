class CreateProductsUsers < ActiveRecord::Migration[5.0]
  def change
    create_table :products_users do |t|
      t.references :product
      t.references :user
    end
    add_index :products_users, [:user_id, :product_id], unique: true
  end
end
