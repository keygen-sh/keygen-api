class DropIndexesForMetrics < ActiveRecord::Migration[5.2]
  def change
    remove_index :metrics, [:account_id, :created_at, :metric]
    remove_index :metrics, :account_id
    remove_index :metrics, :created_at
    remove_index :metrics, :event_type_id
    remove_index :metrics, :metric
  end
end
