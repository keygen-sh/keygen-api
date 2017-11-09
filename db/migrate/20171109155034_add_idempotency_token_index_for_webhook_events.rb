class AddIdempotencyTokenIndexForWebhookEvents < ActiveRecord::Migration[5.0]
  def change
    add_index :webhook_events, :idempotency_token
  end
end
