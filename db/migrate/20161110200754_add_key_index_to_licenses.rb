class AddKeyIndexToLicenses < ActiveRecord::Migration[5.0]
  def change
    add_index :licenses, :key
  end
end
