class AddUserIdAccountIdIndexToLicenseUsers < ActiveRecord::Migration[7.1]
  def change
    add_index :license_users, %i[user_id account_id]
  end
end
