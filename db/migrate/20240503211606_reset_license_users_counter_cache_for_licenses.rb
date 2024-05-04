class ResetLicenseUsersCounterCacheForLicenses < ActiveRecord::Migration[7.1]
  def change
    LicenseUser.find_each do |license_user|
      License.reset_counters(license_user.license_id, :license_users)
    end
  end
end
