class AddFingerprintHashIndexToMachines < ActiveRecord::Migration[5.0]
  def change
    add_index :machines, :fingerprint, name: "machines_hash_fingerprint_idx", using: :hash
  end
end
