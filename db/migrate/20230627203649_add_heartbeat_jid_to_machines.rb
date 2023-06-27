class AddHeartbeatJidToMachines < ActiveRecord::Migration[7.0]
  def change
    add_column :machines, :heartbeat_jid, :string, null: true
  end
end
