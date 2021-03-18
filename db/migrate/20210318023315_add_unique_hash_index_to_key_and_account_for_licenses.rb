class AddUniqueHashIndexToKeyAndAccountForLicenses < ActiveRecord::Migration[5.2]
  disable_ddl_transaction!

  def change
    remove_index(:licenses, name: :licenses_account_id_key_unique_idx) if index_exists?(:licenses, name: :licenses_account_id_key_unique_idx)

    add_index(:licenses, 'account_id, md5(key)', name: :licenses_account_id_key_unique_idx, unique: true, algorithm: :concurrently)
  end
end
