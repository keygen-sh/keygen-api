class AddHeartbeatBasisToPolicies < ActiveRecord::Migration[7.0]
  def change
    add_column :policies, :heartbeat_basis, :string, null: true
  end
end
