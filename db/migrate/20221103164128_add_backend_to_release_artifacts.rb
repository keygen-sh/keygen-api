class AddBackendToReleaseArtifacts < ActiveRecord::Migration[7.0]
  def change
    add_column :release_artifacts, :backend, :string
  end
end
