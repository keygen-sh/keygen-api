class AddApiVersionToWebhookEvents < ActiveRecord::Migration[7.0]
  def change
    add_column :webhook_events, :api_version, :string, null: true
  end
end
