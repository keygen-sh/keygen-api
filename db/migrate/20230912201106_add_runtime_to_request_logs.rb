class AddRuntimeToRequestLogs < ActiveRecord::Migration[7.0]
  def change
    add_column :request_logs, :runtime, :decimal, precision: 8
  end
end
