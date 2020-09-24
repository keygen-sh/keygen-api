class UpdateMultiColumnIndexesForMetrics < ActiveRecord::Migration[5.2]
  disable_ddl_transaction!

  def change
    remove_index :metrics, [:account_id, :created_at, :metric]
    remove_index :metrics, [:id, :created_at]

    add_index :metrics, :account_id, algorithm: :concurrently
    add_index :metrics, :created_at, order: :desc, algorithm: :concurrently
    add_index :metrics, :metric, algorithm: :concurrently
  end
end
