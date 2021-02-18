class AddKeyGinIndexToLicenses < ActiveRecord::Migration[5.2]
  disable_ddl_transaction!

  def change
    remove_index :licenses, name: :licenses_tsv_key_idx

    # TODO(ezekg) This won't work because key values are too big
    # add_index :licenses, :key, algorithm: :concurrently, using: :gin
  end
end
