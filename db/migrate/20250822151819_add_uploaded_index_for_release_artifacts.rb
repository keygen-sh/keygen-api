class AddUploadedIndexForReleaseArtifacts < ActiveRecord::Migration[7.2]
  disable_ddl_transaction!
  verbose!

  def change
    add_index :release_artifacts, %i[account_id release_id], where: %(status = 'UPLOADED'), name: :release_artifacts_uploaded_idx, algorithm: :concurrently
  end
end
