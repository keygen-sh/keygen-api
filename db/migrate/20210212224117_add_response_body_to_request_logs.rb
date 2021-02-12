class AddResponseBodyToRequestLogs < ActiveRecord::Migration[5.2]
  def change
    add_column :request_logs, :response_body, :text
  end
end
