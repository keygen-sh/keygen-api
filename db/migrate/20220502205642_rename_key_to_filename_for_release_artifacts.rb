class RenameKeyToFilenameForReleaseArtifacts < ActiveRecord::Migration[7.0]
  def change
    remove_column :release_artifacts, :filename

    rename_column :release_artifacts, :key, :filename
  end
end
