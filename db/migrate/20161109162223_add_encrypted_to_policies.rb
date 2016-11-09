class AddEncryptedToPolicies < ActiveRecord::Migration[5.0]
  def change
    add_column :policies, :encrypted, :boolean, default: false
  end
end
