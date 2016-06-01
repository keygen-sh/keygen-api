class RemoveBillingIdFromUsers < ActiveRecord::Migration[5.0]
  def change
    remove_column :users, :billing_id, :integer
  end
end
