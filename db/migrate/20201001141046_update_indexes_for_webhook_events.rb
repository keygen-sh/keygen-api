class UpdateIndexesForWebhookEvents < ActiveRecord::Migration[5.2]
  disable_ddl_transaction!

  def change
    remove_index :webhook_events, [:account_id, :created_at]
    remove_index :webhook_events, :created_at
    remove_index :webhook_events, :event

    add_index :webhook_events, [:account_id, :created_at], order: { created_at: :desc }, algorithm: :concurrently
  end
end
