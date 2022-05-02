class RemoveUniqIndexFromReleaseArtifacts < ActiveRecord::Migration[7.0]
  def change
    remove_index :release_artifacts, %i[account_id product_id release_id],
      name: :releases_artifacts_acct_prod_rel_idx
  end
end
