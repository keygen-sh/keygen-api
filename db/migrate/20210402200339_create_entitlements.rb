class CreateEntitlements < ActiveRecord::Migration[6.1]
  def change
    create_table :entitlements, id: :uuid, default: -> { "uuid_generate_v4()" } do |t|
      t.uuid :account_id, null: false
      t.string :name, null: false
      t.string :code, null: false
      t.jsonb :metadata
      t.timestamps
    end

    add_index :entitlements, [:account_id, :code], unique: true
  end
end
