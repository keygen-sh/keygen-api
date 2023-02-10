class AddEnvironmentToLicenseEntitlements < ActiveRecord::Migration[7.0]
  def change
    add_column :license_entitlements, :environment_id, :uuid, null: true

    add_index :license_entitlements, :environment_id
  end
end
