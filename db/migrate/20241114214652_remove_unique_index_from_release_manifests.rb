class RemoveUniqueIndexFromReleaseManifests < ActiveRecord::Migration[7.2]
  disable_ddl_transaction!

  def change
    remove_index :release_manifests, %i[release_artifact_id],
      algorithm: :concurrently,
      unique: true

    add_index :release_manifests, %i[release_artifact_id],
      algorithm: :concurrently
  end
end
