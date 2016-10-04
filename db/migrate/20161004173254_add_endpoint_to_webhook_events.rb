class AddEndpointToWebhookEvents < ActiveRecord::Migration[5.0]
  def change
    add_column :webhook_events, :endpoint, :string
  end
end
