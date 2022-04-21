class AddApiVersionToAccounts < ActiveRecord::Migration[7.0]
  def change
    add_column :accounts, :api_version, :string, null: true
  end
end
