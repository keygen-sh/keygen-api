class AddMetaToLicenses < ActiveRecord::Migration[5.0]
  def change
    add_column :licenses, :meta, :string
  end
end
