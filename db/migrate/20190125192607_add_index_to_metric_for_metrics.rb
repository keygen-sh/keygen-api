# frozen_string_literal: true

class AddIndexToMetricForMetrics < ActiveRecord::Migration[5.2]
  disable_ddl_transaction!

  def change
    add_index :metrics, [:metric, :account_id, :created_at], algorithm: :concurrently
  end
end
