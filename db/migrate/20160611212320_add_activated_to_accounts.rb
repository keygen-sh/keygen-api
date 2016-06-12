class AddActivatedToAccounts < ActiveRecord::Migration[5.0]
  def change
    add_column :accounts, :activated, :boolean, default: false
  end
end
