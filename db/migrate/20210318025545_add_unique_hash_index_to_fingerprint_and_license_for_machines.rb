class AddUniqueHashIndexToFingerprintAndLicenseForMachines < ActiveRecord::Migration[5.2]
  disable_ddl_transaction!

  def change
    remove_index(:machines, name: :machines_license_id_fingerprint_unique_idx) if index_exists?(:machines, name: :machines_license_id_fingerprint_unique_idx)

    add_index(:machines, 'license_id, md5(fingerprint)', name: :machines_license_id_fingerprint_unique_idx, unique: true, algorithm: :concurrently)
  end
end
