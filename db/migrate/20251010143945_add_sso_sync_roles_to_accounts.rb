class AddSsoSyncRolesToAccounts < ActiveRecord::Migration[8.0]
  verbose!

  def change
    add_column :accounts, :sso_sync_roles, :boolean, null: false, default: false
  end
end
