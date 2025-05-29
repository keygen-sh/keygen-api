class AddBackdatedToToReleases < ActiveRecord::Migration[7.2]
  disable_ddl_transaction!
  verbose!

  def change
    add_column :releases, :backdated_to, :timestamp, null: true

    add_index :releases, %i[account_id created_at backdated_to],
      order: { created_at: :desc, backdated_to: :desc },
      algorithm: :concurrently
  end
end
