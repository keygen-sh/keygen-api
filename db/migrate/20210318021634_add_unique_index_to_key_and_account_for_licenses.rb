class AddUniqueIndexToKeyAndAccountForLicenses < ActiveRecord::Migration[5.2]
  disable_ddl_transaction!

  def change
    add_index :licenses, [:account_id, :key], name: :licenses_account_id_key_unique_idx, unique: true, algorithm: :concurrently
  end
end
