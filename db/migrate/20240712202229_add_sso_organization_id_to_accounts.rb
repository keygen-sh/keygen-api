class AddSsoOrganizationIdToAccounts < ActiveRecord::Migration[7.1]
  disable_ddl_transaction!

  def change
    add_column :accounts, :sso_organization_id, :string, null: true
    add_index :accounts, :sso_organization_id, unique: true, algorithm: :concurrently
  end
end
