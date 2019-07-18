# frozen_string_literal: true

class ChangePrimaryKeysToUuid < ActiveRecord::Migration[5.0]
  def up
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
      remove_column table, :id
      rename_column table, :uuid, :id
      execute "ALTER TABLE #{table} ADD PRIMARY KEY (id);"
    end
  end
end
