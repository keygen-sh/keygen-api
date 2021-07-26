class CreateReleaseArtifacts < ActiveRecord::Migration[6.1]
  def change
    create_table :release_artifacts, id: :uuid, default: -> { "uuid_generate_v4()" } do |t|
      t.uuid :account_id, null: false
      t.uuid :product_id, null: false
      t.uuid :release_id, null: false

      t.string :key, null: false
      t.string :etag

      t.timestamps

      t.index %i[account_id product_id release_id], unique: true, name: :releases_artifacts_acct_prod_rel_idx
      t.index %i[key product_id account_id], unique: true
      t.index %i[created_at], order: { created_at: :desc }
    end
  end
end
