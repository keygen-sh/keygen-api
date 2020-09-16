class AddMachineHeartbeatDurationToPolicies < ActiveRecord::Migration[5.2]
  def change
    add_column :policies, :heartbeat_duration, :integer
  end
end
