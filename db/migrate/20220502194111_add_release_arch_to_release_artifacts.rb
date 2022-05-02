class AddReleaseArchToReleaseArtifacts < ActiveRecord::Migration[7.0]
  def change
    add_column :release_artifacts, :release_arch_id, :uuid

    add_index :release_artifacts, %i[release_arch_id]
  end
end
