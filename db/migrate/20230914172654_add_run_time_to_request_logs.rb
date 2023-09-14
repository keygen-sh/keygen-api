class AddRunTimeToRequestLogs < ActiveRecord::Migration[7.0]
  def change
    add_column :request_logs, :run_time, :float
  end
end
