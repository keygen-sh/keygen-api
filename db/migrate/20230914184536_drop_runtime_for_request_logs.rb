class DropRuntimeForRequestLogs < ActiveRecord::Migration[7.0]
  def change
    remove_column :request_logs, :runtime
  end
end
