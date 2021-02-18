class AddKeyGinIndexToLicenses < ActiveRecord::Migration[5.2]
  disable_ddl_transaction!

  def change
    remove_index :licenses, name: :licenses_tsv_key_idx

    add_index :licenses, :key, algorithm: :concurrently, using: :gin
  end
end
