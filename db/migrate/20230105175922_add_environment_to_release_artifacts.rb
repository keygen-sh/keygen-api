class AddEnvironmentToReleaseArtifacts < ActiveRecord::Migration[7.0]
  def change
    add_column :release_artifacts, :environment_id, :uuid, null: true

    add_index :release_artifacts, :environment_id
  end
end
