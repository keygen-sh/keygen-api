class AddLastValidatedVersionToLicenses < ActiveRecord::Migration[7.0]
  def change
    add_column :licenses, :last_validated_version, :string
  end
end
