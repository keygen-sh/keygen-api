class AddGroupIdToMachines < ActiveRecord::Migration[6.1]
  def change
    add_column :machines, :group_id, :uuid, null: true

    add_index :machines, :group_id
  end
end
