class AddExpirationBasisToPolicies < ActiveRecord::Migration[6.1]
  def change
    add_column :policies, :expiration_basis, :string, null: true
  end
end
