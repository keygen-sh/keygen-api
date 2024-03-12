class AddPolicyIdIdAccountIdIndexToLicenses < ActiveRecord::Migration[7.1]
  disable_ddl_transaction!

  def change
    add_index :licenses, %i[policy_id id account_id], unique: true, algorithm: :concurrently
  end
end
