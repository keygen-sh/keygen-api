class RemoveActivatedFromAccounts < ActiveRecord::Migration[5.0]
  def change
    remove_column :accounts, :activated, :boolean
  end
end
