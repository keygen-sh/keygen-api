class RemoveAccountIdFromPolicies < ActiveRecord::Migration[5.0]
  def change
    remove_column :policies, :account_id, :integer
  end
end
