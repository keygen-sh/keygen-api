class AddLastValidatedAtToLicenses < ActiveRecord::Migration[5.2]
  def change
    add_column :licenses, :last_validated_at, :datetime
  end
end
