class AddEnvironmentToEventLogs < ActiveRecord::Migration[7.0]
  def change
    add_column :event_logs, :environment_id, :uuid, null: true

    add_index :event_logs, :environment_id
  end
end
