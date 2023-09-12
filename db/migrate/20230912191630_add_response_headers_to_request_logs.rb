class AddResponseHeadersToRequestLogs < ActiveRecord::Migration[7.0]
  def change
    add_column :request_logs, :response_headers, :jsonb
  end
end
