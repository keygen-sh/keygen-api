class AddStatusToWebhookEvents < ActiveRecord::Migration[6.1]
  def change
    add_column :webhook_events, :status, :string, null: true
  end
end
