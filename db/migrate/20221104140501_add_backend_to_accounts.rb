class AddBackendToAccounts < ActiveRecord::Migration[7.0]
  def change
    add_column :accounts, :backend, :string
  end
end
