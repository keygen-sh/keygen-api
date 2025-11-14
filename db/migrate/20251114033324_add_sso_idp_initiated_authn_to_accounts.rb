class AddSsoIdpInitiatedAuthnToAccounts < ActiveRecord::Migration[8.1]
  verbose!

  def change
    add_column :accounts, :sso_idp_initiated_authn, :boolean, null: false, default: false
  end
end
