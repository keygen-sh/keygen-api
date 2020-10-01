class UpdateIndexesForMetrics < ActiveRecord::Migration[5.2]
  disable_ddl_transaction!

  def change
    remove_index :metrics, [:account_id, :created_at, :event_type_id]
    remove_index :metrics, :metric

    add_index :metrics, [:account_id, :created_at], order: { created_at: :desc }, algorithm: :concurrently
  end
end
