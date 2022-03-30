class AddIndexToLastValidatedAtForLicenses < ActiveRecord::Migration[6.1]
  disable_ddl_transaction!

  def change
    add_index :licenses, :last_validated_at, algorithm: :concurrently
  end
end
