class AddEnvironmentToReleaseChannels < ActiveRecord::Migration[7.0]
  def change
    add_column :release_channels, :environment_id, :uuid, null: true

    add_index :release_channels, :environment_id
  end
end
