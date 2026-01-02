class AddVerToRequestLogs < ActiveRecord::Migration[8.1]
  def change
    add_column :request_logs, :ver, :integer
  end
end
