class AddLicenseUsersCounterCacheToLicenses < ActiveRecord::Migration[7.1]
  def change
    add_column :licenses, :license_users_count, :integer, default: 0, null: false
  end
end
