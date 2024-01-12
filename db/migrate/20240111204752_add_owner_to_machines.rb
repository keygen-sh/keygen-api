class AddOwnerToMachines < ActiveRecord::Migration[7.0]
  def change
    add_column :machines, :owner_id, :uuid, null: true

    add_index :machines, :owner_id
  end
end
