class AddCreatedAtIndexToEventLogs < ActiveRecord::Migration[7.0]
  disable_ddl_transaction!

  def change
    remove_index :event_logs, %i[account_id], algorithm: :concurrently
    add_index :event_logs, %i[account_id created_at],
      order: { created_at: :desc },
      algorithm: :concurrently
  end
end
