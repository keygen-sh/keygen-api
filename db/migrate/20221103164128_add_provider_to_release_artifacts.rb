class AddProviderToReleaseArtifacts < ActiveRecord::Migration[7.0]
  def change
    add_column :release_artifacts, :provider, :string, default: 'S3'
  end
end
