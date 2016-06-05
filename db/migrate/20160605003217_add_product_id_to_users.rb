class AddProductIdToUsers < ActiveRecord::Migration[5.0]
  def change
    add_column :users, :product_id, :integer
  end
end
