class AddIndexesToLicenseUsers < ActiveRecord::Migration[7.1]
  disable_ddl_transaction!

  def change
    remove_index :license_users, %i[license_id user_id account_id], unique: true, algorithm: :concurrently, if_exists: true
    add_index :license_users, %i[account_id license_id user_id], unique: true, algorithm: :concurrently, if_not_exists: true
    add_index :license_users, %i[license_id], algorithm: :concurrently, if_not_exists: true
  end
end
