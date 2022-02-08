class AddHeartbeatCullStrategyToPolicies < ActiveRecord::Migration[6.1]
  def change
    add_column :policies, :heartbeat_cull_strategy, :string, null: true
  end
end
