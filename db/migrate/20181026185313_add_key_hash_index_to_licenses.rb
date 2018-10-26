class AddKeyHashIndexToLicenses < ActiveRecord::Migration[5.0]
  def change
    add_index :licenses, :key, name: "licenses_hash_key_idx", using: :hash
  end
end
