class AddRenewalBasisToPolicies < ActiveRecord::Migration[7.0]
  def change
    add_column :policies, :renewal_basis, :string, null: true
  end
end
