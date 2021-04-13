class AddAccountIdIndexToMetrics < ActiveRecord::Migration[6.1]
  disable_ddl_transaction!

  def change
    add_index :metrics, :account_id, algorithm: :concurrently
  end
end
