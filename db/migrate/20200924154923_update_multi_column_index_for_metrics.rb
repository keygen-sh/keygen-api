class UpdateMultiColumnIndexForMetrics < ActiveRecord::Migration[5.2]
  disable_ddl_transaction!

  def change
    remove_index :metrics, [:created_at, :account_id, :metric]

    add_index :metrics, [:account_id, :metric], algorithm: :concurrently
  end
end
