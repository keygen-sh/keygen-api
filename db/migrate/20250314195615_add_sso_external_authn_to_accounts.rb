class AddSsoExternalAuthnToAccounts < ActiveRecord::Migration[7.2]
  def change
    add_column :accounts, :sso_external_authn, :boolean, null: false, default: false
  end
end
