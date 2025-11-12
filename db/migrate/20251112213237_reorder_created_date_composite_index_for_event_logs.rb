class ReorderCreatedDateCompositeIndexForEventLogs < ActiveRecord::Migration[8.1]
  disable_ddl_transaction!
  verbose!

  def change
    remove_index :event_logs, %i[account_id created_date], algorithm: :concurrently

    add_index :event_logs, %i[created_date account_id],
      order: { created_date: :desc },
      algorithm: :concurrently
  end
end
