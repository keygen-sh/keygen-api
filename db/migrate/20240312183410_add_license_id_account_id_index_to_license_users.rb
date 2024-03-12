class AddLicenseIdAccountIdIndexToLicenseUsers < ActiveRecord::Migration[7.1]
  def change
    add_index :license_users, %i[license_id account_id]
  end
end
