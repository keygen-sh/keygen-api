class DropEventForWebhookEvents < ActiveRecord::Migration[5.2]
  def change
    remove_column :webhook_events, :event
  end
end
