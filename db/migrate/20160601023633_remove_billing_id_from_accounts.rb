class RemoveBillingIdFromAccounts < ActiveRecord::Migration[5.0]
  def change
    remove_column :accounts, :billing_id, :integer
  end
end
