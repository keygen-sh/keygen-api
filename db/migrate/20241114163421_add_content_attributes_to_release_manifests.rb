class AddContentAttributesToReleaseManifests < ActiveRecord::Migration[7.2]
  disable_ddl_transaction!

  def change
    add_column :release_manifests, :content_path,   :string, null: true
    add_column :release_manifests, :content_type,   :string, null: true
    add_column :release_manifests, :content_length, :bigint, null: true
    add_column :release_manifests, :content_digest, :string, null: true

    add_index :release_manifests, %i[content_path release_artifact_id],
      algorithm: :concurrently,
      unique: true

    add_index :release_manifests, %i[content_digest release_artifact_id],
      algorithm: :concurrently,
      unique: true

    add_index :release_manifests, %i[content_type release_artifact_id],
      algorithm: :concurrently
  end
end
