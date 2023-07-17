class CreateReleaseEngines < ActiveRecord::Migration[7.0]
  def change
    create_table :release_engines, id: :uuid, default: -> { 'uuid_generate_v4()' } do |t|
      t.string :name, null: false
      t.string :key, null: false

      t.timestamps

      t.index :key, unique: true
    end
  end
end
