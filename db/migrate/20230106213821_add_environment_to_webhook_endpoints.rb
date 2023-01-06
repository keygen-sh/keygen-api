class AddEnvironmentToWebhookEndpoints < ActiveRecord::Migration[7.0]
  def change
    add_column :webhook_endpoints, :environment_id, :uuid, null: true

    add_index :webhook_endpoints, :environment_id
  end
end
