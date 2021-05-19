class CreateReleaseFiletypes < ActiveRecord::Migration[6.1]
  def change
    create_table :release_filetypes, id: :uuid, default: -> { "uuid_generate_v4()" } do |t|
      t.uuid :account_id, null: false

      t.string :name
      t.string :key

      t.timestamps

      t.index %i[account_id created_at], order: { created_at: :desc }
      t.index %i[account_id key], unique: true
    end
  end
end
