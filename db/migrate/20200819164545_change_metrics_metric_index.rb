# frozen_string_literal: true

class ChangeMetricsMetricIndex < ActiveRecord::Migration[5.2]
  disable_ddl_transaction!

  def change
    remove_index :metrics, [:metric, :account_id, :created_at]

    add_index :metrics, :metric, algorithm: :concurrently
  end
end
