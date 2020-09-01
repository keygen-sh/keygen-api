class AddEventIndexToWebhookEvents < ActiveRecord::Migration[5.2]
  disable_ddl_transaction!

  def change
    add_index :webhook_events, :event, algorithm: :concurrently
  end
end
