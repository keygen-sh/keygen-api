class AddStatusToReleaseArtifacts < ActiveRecord::Migration[7.0]
  def change
    add_column :release_artifacts, :status, :string, null: true

    add_index :release_artifacts, :status
  end
end
