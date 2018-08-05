class AddEncryptionSchemeToPolicies < ActiveRecord::Migration[5.0]
  def change
    add_column :policies, :encryption_scheme, :string
  end
end
