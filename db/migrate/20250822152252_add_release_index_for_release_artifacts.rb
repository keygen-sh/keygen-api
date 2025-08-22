class AddReleaseIndexForReleaseArtifacts < ActiveRecord::Migration[7.2]
  disable_ddl_transaction!
  verbose!

  def change
    add_index :release_artifacts, :release_id, algorithm: :concurrently
  end
end
