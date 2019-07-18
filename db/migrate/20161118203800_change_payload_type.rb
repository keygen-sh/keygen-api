# frozen_string_literal: true

class ChangePayloadType < ActiveRecord::Migration[5.0]
  def change
    change_column :webhook_events, :payload, :text
  end
end
