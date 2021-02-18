class AddFingerprintGinIndexToMachines < ActiveRecord::Migration[5.2]
  disable_ddl_transaction!

  def change
    remove_index :machines, name: :machines_tsv_fingerprint_idx

    add_index :machines, :fingerprint, algorithm: :concurrently, using: :gin
  end
end
