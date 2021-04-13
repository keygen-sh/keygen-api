class UpdateCreatedAtIndexForMetrics < ActiveRecord::Migration[6.1]
  disable_ddl_transaction!

  def change
    remove_index(:metrics, [:account_id, :created_at]) if index_exists?(:metrics, [:account_id, :created_at])

    add_index(:metrics, :created_at, algorithm: :concurrently)
  end
end
