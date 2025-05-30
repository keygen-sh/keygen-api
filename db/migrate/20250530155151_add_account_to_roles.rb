class AddAccountToRoles < ActiveRecord::Migration[7.2]
  disable_ddl_transaction!
  verbose!

  def change
    add_column :roles, :account_id, :uuid, null: true, if_not_exists: true # FIXME(ezekg) make not-null

    add_index :roles, :account_id, algorithm: :concurrently, if_not_exists: true
  end
end
