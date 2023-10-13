class AddCreatedDateToEventLogs < ActiveRecord::Migration[7.0]
  disable_ddl_transaction!

  def change
    add_column :event_logs, :created_date, :date, null: true

    add_index :event_logs, %i[account_id created_date],
      order: { created_date: :desc },
      algorithm: :concurrently
  end
end
