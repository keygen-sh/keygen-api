class AddSsoOrganizationDomainToAccounts < ActiveRecord::Migration[7.2]
  disable_ddl_transaction!

  def change
    add_column :accounts, :sso_organization_domains, :string, array: true, default: []
    add_index :accounts, :sso_organization_domains, algorithm: :concurrently, using: :gin
  end
end
