class AddHeartbeatJidToMachineProcesses < ActiveRecord::Migration[7.0]
  def change
    add_column :machine_processes, :heartbeat_jid, :string, null: true
  end
end
