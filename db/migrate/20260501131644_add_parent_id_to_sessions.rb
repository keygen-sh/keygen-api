# frozen_string_literal: true

class AddParentIdToSessions < ActiveRecord::Migration[8.1]
  disable_ddl_transaction!
  verbose!

  def change
    add_column :sessions, :parent_id, :uuid
    add_index :sessions, :parent_id, algorithm: :concurrently
  end
end
