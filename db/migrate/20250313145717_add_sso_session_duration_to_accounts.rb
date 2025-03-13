class AddSsoSessionDurationToAccounts < ActiveRecord::Migration[7.2]
  def change
    add_column :accounts, :sso_session_duration, :integer
  end
end
