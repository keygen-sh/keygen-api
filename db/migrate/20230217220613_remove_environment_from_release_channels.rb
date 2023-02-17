class RemoveEnvironmentFromReleaseChannels < ActiveRecord::Migration[7.0]
  def change
    remove_column :release_channels, :environment_id
  end
end
