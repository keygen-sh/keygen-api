class UpdateKeyUniqIndexForReleaseArtifacts < ActiveRecord::Migration[7.0]
  def change
    remove_index :release_artifacts, %i[key product_id account_id]

    add_index :release_artifacts, %i[key product_id account_id],
      name: :release_artifacts_uniq_key_idx,
      where: 'key is not null',
      unique: true
  end
end
