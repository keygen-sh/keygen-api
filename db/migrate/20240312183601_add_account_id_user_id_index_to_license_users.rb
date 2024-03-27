class AddAccountIdUserIdIndexToLicenseUsers < ActiveRecord::Migration[7.1]
  def change
    add_index :license_users, %i[account_id user_id]
  end
end
