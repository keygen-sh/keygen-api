class AddIndexToResourceIds < ActiveRecord::Migration[5.0]
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
      add_index table, :id, unique: true
    end

    remove_index :accounts, :slug
    add_index :accounts, [:slug, :id]
  end
end
