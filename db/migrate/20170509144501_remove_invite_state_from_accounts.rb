class RemoveInviteStateFromAccounts < ActiveRecord::Migration[5.0]
  def change
    remove_column :accounts, :invite_state
    remove_column :accounts, :invite_token
    remove_column :accounts, :invite_sent_at
  end
end
