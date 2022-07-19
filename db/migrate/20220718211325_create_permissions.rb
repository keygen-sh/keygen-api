class CreatePermissions < ActiveRecord::Migration[7.0]
  def change
    create_table :permissions, id: :uuid, default: -> { 'uuid_generate_v4()' } do |t|
      t.string :action, null: false

      t.timestamps

      t.index :action, unique: true
    end
  end
end
