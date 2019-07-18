# frozen_string_literal: true

class AddCreatedAtIndices < ActiveRecord::Migration[5.0]
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
      add_index table, :created_at, where: "deleted_at IS NULL"
    end
  end
end
