class AddQueueTimeToRequestLogs < ActiveRecord::Migration[7.0]
  def change
    add_column :request_logs, :queue_time, :float
  end
end
