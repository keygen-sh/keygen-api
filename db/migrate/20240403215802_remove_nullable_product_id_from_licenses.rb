class RemoveNullableProductIdFromLicenses < ActiveRecord::Migration[7.1]
  def up
    change_column_null :licenses, :product_id, false
  end

  def down
    change_column_null :licenses, :product_id, true
  end
end
