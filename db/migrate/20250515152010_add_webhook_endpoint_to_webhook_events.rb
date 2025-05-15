class AddWebhookEndpointToWebhookEvents < ActiveRecord::Migration[7.2]
  disable_ddl_transaction!

  def change
    add_column :webhook_events, :webhook_endpoint_id, :uuid, null: true # FIXME(ezekg) make not-null

    add_index :webhook_events, :webhook_endpoint_id, algorithm: :concurrently
  end
end
