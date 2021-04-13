class UpdateCreatedAtIndexOrderForMetrics < ActiveRecord::Migration[6.1]
  disable_ddl_transaction!

  def change
    remove_index(:metrics, :created_at) if index_exists?(:metrics, :created_at)

    add_index(:metrics, :created_at, order: { created_at: :desc }, algorithm: :concurrently)
  end
end
