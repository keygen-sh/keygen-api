class AddProtectedToAccounts < ActiveRecord::Migration[5.0]
  def change
    add_column :accounts, :protected, :boolean, default: false
  end
end
