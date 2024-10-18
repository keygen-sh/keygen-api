class CreateReleaseManifests < ActiveRecord::Migration[7.1]
  def change
    create_table :release_manifests, id: :uuid, default: -> { 'uuid_generate_v4()' }, if_not_exists: true do |t|
      t.uuid :account_id,          null: false
      t.uuid :environment_id,      null: true
      t.uuid :release_id,          null: false
      t.uuid :release_artifact_id, null: false
      t.uuid :release_package_id,  null: false
      t.uuid :release_engine_id,   null: false

      t.jsonb :metadata, null: false, default: {}

      t.timestamps

      t.index %i[account_id created_at], order: { created_at: :desc }
      t.index %i[environment_id]
      t.index %i[release_id],            unique: true
      t.index %i[release_package_id]
      t.index %i[release_engine_id]
      t.index %i[release_artifact_id],   unique: true
    end
  end
end
