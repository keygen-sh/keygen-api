# frozen_string_literal: true

class AddEventToWebhookEvents < ActiveRecord::Migration[5.0]
  def change
    add_column :webhook_events, :event, :string
  end
end
