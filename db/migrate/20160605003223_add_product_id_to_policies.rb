class AddProductIdToPolicies < ActiveRecord::Migration[5.0]
  def change
    add_column :policies, :product_id, :integer
  end
end
