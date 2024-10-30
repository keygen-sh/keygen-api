class CreateReleaseManifests < ActiveRecord::Migration[7.1]
  def change
    create_table :release_manifests, id: :uuid, default: -> { 'uuid_generate_v4()' } do |t|
      t.uuid :account_id,          null: false
      t.uuid :environment_id,      null: true
      t.uuid :release_id,          null: false
      t.uuid :release_artifact_id, null: false

      t.blob :content,   null: false
      t.jsonb :metadata

      t.timestamps

      t.index %i[account_id created_at], order: { created_at: :desc }
      t.index %i[environment_id]
      t.index %i[release_id]
      t.index %i[release_artifact_id],   unique: true
    end
  end
end
