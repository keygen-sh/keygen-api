class AddReleasePackageToReleases < ActiveRecord::Migration[7.0]
  def change
    add_column :releases, :release_package_id, :uuid, null: true

    add_index :releases, :release_package_id
  end
end
