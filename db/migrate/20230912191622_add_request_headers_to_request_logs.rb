class AddRequestHeadersToRequestLogs < ActiveRecord::Migration[7.0]
  def change
    add_column :request_logs, :request_headers, :jsonb
  end
end
