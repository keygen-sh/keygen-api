class AddNullableReleasePlatformForReleases < ActiveRecord::Migration[6.1]
  def up
    change_column :releases, :release_platform_id, :uuid, null: true
  end

  def down
    change_column :releases, :release_platform_id, :uuid, null: false
  end
end
