class AddIndicesToWebhooks < ActiveRecord::Migration[5.0]
  def change
    add_index :webhook_endpoints, :account_id

    add_index :webhook_events, :account_id
    add_index :webhook_events, :jid
  end
end
