class AddContentAttributesToReleaseManifests < ActiveRecord::Migration[7.2]
  disable_ddl_transaction!

  def change
    # FIXME(ezekg) eventually make these non-null?
    add_column :release_manifests, :content_type,   :string, null: true
    add_column :release_manifests, :content_length, :bigint, null: true
    add_column :release_manifests, :content_digest, :string, null: true

    add_index :release_manifests, %i[release_artifact_id content_digest],
      algorithm: :concurrently,
      unique: true
  end
end
