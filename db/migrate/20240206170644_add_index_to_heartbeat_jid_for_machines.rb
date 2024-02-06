class AddIndexToHeartbeatJidForMachines < ActiveRecord::Migration[7.1]
  def change
    add_index :machines, :heartbeat_jid
  end
end
