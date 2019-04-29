class UpdateIndexSortOrders < ActiveRecord::Migration[5.2]
  disable_ddl_transaction!

  TABLES = [
    :accounts,
    :billings,
    :keys,
    :licenses,
    :machines,
    :plans,
    :policies,
    :products,
    :receipts,
    :roles,
    :tokens,
    :users,
    :webhook_endpoints,
    :webhook_events
  ]

  def change
    TABLES.each do |table|
      add_index table, :created_at, order: { created_at: :desc }, algorithm: :concurrently
    end
  end
end
