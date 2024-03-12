class AddAccountIdLicenseIdIndexToLicenseUsers < ActiveRecord::Migration[7.1]
  def change
    add_index :license_users, %i[account_id license_id]
  end
end
