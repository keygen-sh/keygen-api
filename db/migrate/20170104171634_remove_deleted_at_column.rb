class RemoveDeletedAtColumn < ActiveRecord::Migration[5.0]
  def change
    tables = [
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

    tables.each do |table|
      remove_column table, :deleted_at, :datetime
    end
  end
end
