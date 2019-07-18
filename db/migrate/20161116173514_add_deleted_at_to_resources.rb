# frozen_string_literal: true

class AddDeletedAtToResources < ActiveRecord::Migration[5.0]
  def change
    add_column :accounts, :deleted_at, :datetime
    add_index :accounts, :deleted_at

    add_column :billings, :deleted_at, :datetime
    add_index :billings, :deleted_at

    add_column :keys, :deleted_at, :datetime
    add_index :keys, :deleted_at

    add_column :licenses, :deleted_at, :datetime
    add_index :licenses, :deleted_at

    add_column :machines, :deleted_at, :datetime
    add_index :machines, :deleted_at

    add_column :plans, :deleted_at, :datetime
    add_index :plans, :deleted_at

    add_column :policies, :deleted_at, :datetime
    add_index :policies, :deleted_at

    add_column :products, :deleted_at, :datetime
    add_index :products, :deleted_at

    add_column :receipts, :deleted_at, :datetime
    add_index :receipts, :deleted_at

    add_column :roles, :deleted_at, :datetime
    add_index :roles, :deleted_at

    add_column :tokens, :deleted_at, :datetime
    add_index :tokens, :deleted_at

    add_column :users, :deleted_at, :datetime
    add_index :users, :deleted_at

    add_column :webhook_endpoints, :deleted_at, :datetime
    add_index :webhook_endpoints, :deleted_at

    add_column :webhook_events, :deleted_at, :datetime
    add_index :webhook_events, :deleted_at
  end
end
