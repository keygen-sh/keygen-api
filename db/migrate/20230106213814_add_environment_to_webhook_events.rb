class AddEnvironmentToWebhookEvents < ActiveRecord::Migration[7.0]
  def change
    add_column :webhook_events, :environment_id, :uuid, null: true

    add_index :webhook_events, :environment_id
  end
end
