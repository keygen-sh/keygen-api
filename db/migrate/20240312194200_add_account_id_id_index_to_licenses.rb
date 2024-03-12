class AddAccountIdIdIndexToLicenses < ActiveRecord::Migration[7.1]
  disable_ddl_transaction!

  def change
    add_index :licenses, %i[account_id id], unique: true, algorithm: :concurrently
  end
end
