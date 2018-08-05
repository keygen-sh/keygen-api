class AddSignatureToLicenses < ActiveRecord::Migration[5.0]
  def change
    add_column :licenses, :signature, :string
  end
end
