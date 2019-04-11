class AddTokenIdToRequestLogs < ActiveRecord::Migration[5.2]
  def change
    add_column :request_logs, :token_id, :uuid
  end
end
