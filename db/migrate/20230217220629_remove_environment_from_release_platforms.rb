class RemoveEnvironmentFromReleasePlatforms < ActiveRecord::Migration[7.0]
  def change
    remove_column :release_platforms, :environment_id
  end
end
