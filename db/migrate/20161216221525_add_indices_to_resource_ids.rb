class AddIndicesToResourceIds < ActiveRecord::Migration[5.0]
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
      add_index table, :id, where: "deleted_at IS NULL"
    end
  end
end
