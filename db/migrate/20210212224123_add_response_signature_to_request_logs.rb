class AddResponseSignatureToRequestLogs < ActiveRecord::Migration[5.2]
  def change
    add_column :request_logs, :response_signature, :text
  end
end
