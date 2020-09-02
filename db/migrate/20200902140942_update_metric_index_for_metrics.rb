class UpdateMetricIndexForMetrics < ActiveRecord::Migration[5.2]
  disable_ddl_transaction!

  def change
    remove_index :metrics, [:account_id, :created_at]
    remove_index :metrics, :metric

    add_index :metrics, [:account_id, :created_at, :metric], algorithm: :concurrently
  end
end
