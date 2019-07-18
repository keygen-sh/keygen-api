# frozen_string_literal: true

class CreateWebhookEvents < ActiveRecord::Migration[5.0]
  def change
    create_table :webhook_events do |t|
      t.integer :account_id
      t.string :payload
      t.string :jid

      t.timestamps
    end
  end
end
