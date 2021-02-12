class AddRequestBodyToRequestLogs < ActiveRecord::Migration[5.2]
  def change
    add_column :request_logs, :request_body, :text
  end
end
