class RemoveActivationFromAccounts < ActiveRecord::Migration[5.0]
  def change
    remove_column :accounts, :activation_token, :string
    remove_column :accounts, :activation_sent_at, :datetime
  end
end
