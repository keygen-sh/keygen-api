class AddSeedMigrationIndexesForMetrics < ActiveRecord::Migration[5.2]
  disable_ddl_transaction!

  def change
    add_index :metrics, :event_type_id, algorithm: :concurrently
    add_index :metrics, :metric, algorithm: :concurrently
  end
end
