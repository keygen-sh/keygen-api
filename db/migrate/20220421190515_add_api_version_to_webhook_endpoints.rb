class AddApiVersionToWebhookEndpoints < ActiveRecord::Migration[7.0]
  def change
    add_column :webhook_endpoints, :api_version, :string, null: true
  end
end
