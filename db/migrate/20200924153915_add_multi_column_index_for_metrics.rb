class AddMultiColumnIndexForMetrics < ActiveRecord::Migration[5.2]
  disable_ddl_transaction!

  def change
    add_index :metrics, [:created_at, :account_id, :metric], algorithm: :concurrently
  end
end
