class CreateReleasePlatforms < ActiveRecord::Migration[6.1]
  def change
    create_table :release_platforms, id: :uuid, default: -> { "uuid_generate_v4()" } do |t|
      t.uuid :account_id, null: false

      t.string :name
      t.string :key
      t.jsonb :metadata

      t.timestamps

      t.index %i[account_id created_at], order: { created_at: :desc }
      t.index %i[account_id key], unique: true
    end
  end
end
