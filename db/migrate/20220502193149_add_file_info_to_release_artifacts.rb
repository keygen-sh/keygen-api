class AddFileInfoToReleaseArtifacts < ActiveRecord::Migration[7.0]
  def change
    add_column :release_artifacts, :release_platform_id, :uuid
    add_column :release_artifacts, :release_filetype_id, :uuid

    # TODO(ezekg) We should migrate and drop the `key` column
    change_column_null :release_artifacts, :key, true

    add_column :release_artifacts, :filename,  :string
    add_column :release_artifacts, :filesize,  :bigint
    add_column :release_artifacts, :signature, :string
    add_column :release_artifacts, :checksum,  :string

    add_index :release_artifacts, %i[release_id filename], unique: true
    add_index :release_artifacts, %i[release_platform_id]
    add_index :release_artifacts, %i[release_filetype_id]
    add_index :release_artifacts, %i[filename]
  end
end
