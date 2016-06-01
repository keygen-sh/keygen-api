class AddBillingToUsers < ActiveRecord::Migration[5.0]
  def change
    add_column :users, :billing_id, :integer
  end
end
