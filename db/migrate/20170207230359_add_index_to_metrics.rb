# frozen_string_literal: true

class AddIndexToMetrics < ActiveRecord::Migration[5.0]
  def change
    add_index :metrics, [:created_at, :id], unique: true
    add_index :metrics, [:created_at, :account_id]
  end
end
