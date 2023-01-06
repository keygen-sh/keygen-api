class AddEnvironmentToRequestLogs < ActiveRecord::Migration[7.0]
  def change
    add_column :request_logs, :environment_id, :uuid, null: true

    add_index :request_logs, :environment_id
  end
end
