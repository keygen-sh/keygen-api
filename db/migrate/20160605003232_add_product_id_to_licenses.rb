class AddProductIdToLicenses < ActiveRecord::Migration[5.0]
  def change
    add_column :licenses, :product_id, :integer
  end
end
