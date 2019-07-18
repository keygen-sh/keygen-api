# frozen_string_literal: true

class CreateWebhookEndpoints < ActiveRecord::Migration[5.0]
  def change
    create_table :webhook_endpoints do |t|
      t.integer :account_id
      t.string :url

      t.timestamps
    end
  end
end
