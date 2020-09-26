class AddIndexesForMetrics < ActiveRecord::Migration[5.2]
  disable_ddl_transaction!

  def change
    add_index :metrics, [:account_id, :created_at, :event_type_id], algorithm: :concurrently
  end
end
