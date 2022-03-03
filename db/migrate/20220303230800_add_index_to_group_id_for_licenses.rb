class AddIndexToGroupIdForLicenses < ActiveRecord::Migration[6.1]
  disable_ddl_transaction!

  def change
    add_index :licenses, :group_id, algorithm: :concurrently
  end
end
