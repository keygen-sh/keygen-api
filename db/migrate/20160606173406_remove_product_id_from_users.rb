class RemoveProductIdFromUsers < ActiveRecord::Migration[5.0]
  def change
    remove_column :users, :product_id, :integer
  end
end
