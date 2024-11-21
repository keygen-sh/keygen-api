class CreateReleaseDescriptors < ActiveRecord::Migration[7.2]
  def change
    create_table :release_descriptors, id: :uuid, default: -> { 'uuid_generate_v4()' } do |t|
      t.uuid :account_id,          null: false
      t.uuid :environment_id,      null: true
      t.uuid :release_id,          null: false
      t.uuid :release_artifact_id, null: false

      t.string :content_path,   null: false
      t.string :content_type,   null: false
      t.bigint :content_length, null: false
      t.string :content_digest, null: false
      t.jsonb :metadata

      t.timestamps

      t.index %i[account_id created_at],              order: { created_at: :desc }
      t.index %i[environment_id]
      t.index %i[release_id]
      t.index %i[release_artifact_id]
      t.index %i[content_path release_artifact_id],   unique: true
      t.index %i[content_digest release_artifact_id], unique: true
      t.index %i[content_type release_artifact_id]
    end
  end
end
