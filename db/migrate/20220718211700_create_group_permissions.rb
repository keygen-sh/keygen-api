class CreateGroupPermissions < ActiveRecord::Migration[7.0]
  def change
    create_table :group_permissions, id: :uuid, default: -> { 'uuid_generate_v4()' } do |t|
      t.uuid :permission_id, null: false, index: true
      t.uuid :group_id,      null: false, index: true

      t.timestamps
    end
  end
end
