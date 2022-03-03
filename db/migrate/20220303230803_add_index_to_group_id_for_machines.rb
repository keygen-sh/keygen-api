class AddIndexToGroupIdForMachines < ActiveRecord::Migration[6.1]
  disable_ddl_transaction!

  def change
    add_index :machines, :group_id, algorithm: :concurrently
  end
end
