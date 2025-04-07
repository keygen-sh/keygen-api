class AddHeartbeatCullIndexesToPolicies < ActiveRecord::Migration[7.2]
  disable_ddl_transaction!
  verbose!

  def change
    add_index :policies, :heartbeat_cull_strategy, algorithm: :concurrently
    add_index :policies, :require_heartbeat, algorithm: :concurrently
  end
end
