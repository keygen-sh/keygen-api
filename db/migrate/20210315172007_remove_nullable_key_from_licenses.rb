class RemoveNullableKeyFromLicenses < ActiveRecord::Migration[5.2]
  def up
    change_column :licenses, :key, :string, null: false
  end

  def down
    change_column :licenses, :key, :string, null: true
  end
end
