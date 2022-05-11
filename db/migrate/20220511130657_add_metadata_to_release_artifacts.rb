class AddMetadataToReleaseArtifacts < ActiveRecord::Migration[7.0]
  def change
    add_column :release_artifacts, :metadata, :jsonb, null: true
  end
end
