class AddSsoJitProvisioningToAccounts < ActiveRecord::Migration[7.2]
  def change
    add_column :accounts, :sso_jit_provisioning, :boolean, null: false, default: false
  end
end
