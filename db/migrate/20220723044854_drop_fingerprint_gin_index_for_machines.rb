class DropFingerprintGinIndexForMachines < ActiveRecord::Migration[7.0]
  disable_ddl_transaction!

  def change
    remove_index :machines, :fingerprint, name: :index_machines_on_fingerprint, algorithm: :concurrently, using: :gin
  end
end
