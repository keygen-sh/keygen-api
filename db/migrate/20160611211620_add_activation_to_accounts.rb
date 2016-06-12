class AddActivationToAccounts < ActiveRecord::Migration[5.0]
  def change
    add_column :accounts, :activation_token, :string
    add_column :accounts, :activation_sent_at, :datetime
  end
end
