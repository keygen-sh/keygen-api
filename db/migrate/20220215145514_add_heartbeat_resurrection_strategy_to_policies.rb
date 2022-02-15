class AddHeartbeatResurrectionStrategyToPolicies < ActiveRecord::Migration[6.1]
  def change
    add_column :policies, :heartbeat_resurrection_strategy, :string, null: true
  end
end
