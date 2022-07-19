class CreateTokenPermissions < ActiveRecord::Migration[7.0]
  def change
    create_table :token_permissions, id: :uuid, default: -> { 'uuid_generate_v4()' } do |t|
      t.uuid :permission_id, null: false, index: true
      t.uuid :token_id,      null: false

      t.timestamps

      t.index %i[token_id permission_id], unique: true
    end
  end
end
