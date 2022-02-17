class AddRequireHeartbeatToPolicies < ActiveRecord::Migration[6.1]
  def change
    add_column :policies, :require_heartbeat, :boolean, default: false, null: false
  end
end
