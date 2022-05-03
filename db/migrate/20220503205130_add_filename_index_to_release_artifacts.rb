class AddFilenameIndexToReleaseArtifacts < ActiveRecord::Migration[7.0]
  def change
    add_index :release_artifacts, %i[filename release_id account_id],
      name: :release_artifacts_uniq_filename_idx,
      where: 'filename is not null',
      unique: true
  end
end
