class CreateReleaseEngines < ActiveRecord::Migration[7.0]
  def change
    create_table :release_engines, id: :uuid, default: -> { 'uuid_generate_v4()' } do |t|
      t.uuid :account_id, null: false

      t.string :name, null: true
      t.string :key, null: false

      t.timestamps

      t.index %i[account_id created_at], order: { created_at: :desc }
      t.index %i[account_id key], unique: true
    end
  end
end
