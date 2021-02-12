class AddResourceToRequestLogs < ActiveRecord::Migration[5.2]
  def change
    add_column :request_logs, :resource_type, :string
    add_column :request_logs, :resource_id, :uuid
  end
end
