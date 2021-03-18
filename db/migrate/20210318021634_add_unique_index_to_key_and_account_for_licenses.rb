class AddUniqueIndexToKeyAndAccountForLicenses < ActiveRecord::Migration[5.2]
  disable_ddl_transaction!

  def change
    add_index :licenses, [:account_id, :key], unique: true, algorithm: :concurrently
  end
end
