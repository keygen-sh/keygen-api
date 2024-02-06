class AddIndexToHeartbeatJidForMachineProcesses < ActiveRecord::Migration[7.1]
  def change
    add_index :machine_processes, :heartbeat_jid
  end
end
