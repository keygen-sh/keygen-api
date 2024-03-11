class AddIdPolicyIdIndexToLicenses < ActiveRecord::Migration[7.1]
  disable_ddl_transaction!

  def change
    add_index :licenses, %i[id policy_id account_id], algorithm: :concurrently
  end
end
