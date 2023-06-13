class AddLastValidatedChecksumToLicenses < ActiveRecord::Migration[7.0]
  def change
    add_column :licenses, :last_validated_checksum, :string
  end
end
