class ReorderCreatedDateCompositeIndexForRequestLogs < ActiveRecord::Migration[8.1]
  disable_ddl_transaction!
  verbose!

  def change
    remove_index :request_logs, %i[account_id created_date], algorithm: :concurrently, if_exists: true

    add_index :request_logs, %i[created_date account_id],
      order: { created_date: :desc },
      algorithm: :concurrently,
      if_not_exists: true
  end
end
