class AddIndexToLastHeartbeatAtToMachines < ActiveRecord::Migration[6.1]
  disable_ddl_transaction!

  def change
    add_index :machines, :last_heartbeat_at, algorithm: :concurrently
  end
end
