# frozen_string_literal: true

class AddLastHeartbeatAtToMachines < ActiveRecord::Migration[5.2]
  def change
    add_column :machines, :last_heartbeat_at, :datetime
  end
end
