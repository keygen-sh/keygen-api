class RemoveProductIdFromReleaseArtifacts < ActiveRecord::Migration[7.0]
  def change
    remove_column :release_artifacts, :product_id
  end
end
