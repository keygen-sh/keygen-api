class AddAccountIdToPools < ActiveRecord::Migration[5.0]
  def change
    add_column :pools, :account_id, :integer
  end
end
