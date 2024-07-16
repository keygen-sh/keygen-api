class AddSsoOrganizationDomainToAccounts < ActiveRecord::Migration[7.1]
  def change
    add_column :accounts, :sso_organization_domains, :string, array: true, default: []
  end
end
