class AddNameToLicenses < ActiveRecord::Migration[5.0]
  def change
    add_column :licenses, :name, :string
  end
end
