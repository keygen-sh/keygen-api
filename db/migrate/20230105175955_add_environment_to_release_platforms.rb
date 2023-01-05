class AddEnvironmentToReleasePlatforms < ActiveRecord::Migration[7.0]
  def change
    add_column :release_platforms, :environment_id, :uuid, null: true

    add_index :release_platforms, :environment_id
  end
end
