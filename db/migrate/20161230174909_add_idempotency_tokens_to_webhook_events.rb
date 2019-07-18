# frozen_string_literal: true

class AddIdempotencyTokensToWebhookEvents < ActiveRecord::Migration[5.0]
  def change
    add_column :webhook_events, :idempotency_token, :string
  end
end
