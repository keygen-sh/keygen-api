class AddResponseToWebhookEvents < ActiveRecord::Migration[5.0]
  def change
    add_column :webhook_events, :last_response_code, :integer
    add_column :webhook_events, :last_response_body, :text
  end
end
