class CreateRolePermissions < ActiveRecord::Migration[7.0]
  def change
    create_table :role_permissions, id: :uuid, default: -> { 'uuid_generate_v4()' } do |t|
      t.uuid :permission_id, null: false, index: true
      t.uuid :role_id,       null: false, index: true

      t.timestamps
    end
  end
end
