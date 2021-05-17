class RemoveRequireLicenseKeyFromReleases < ActiveRecord::Migration[6.1]
  def change
    remove_column :releases, :require_license_key
  end
end
