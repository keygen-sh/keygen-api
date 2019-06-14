class AddQueryParamsToRequestLogs < ActiveRecord::Migration[5.2]
  def change
    add_column :request_logs, :query_params, :jsonb
  end
end
