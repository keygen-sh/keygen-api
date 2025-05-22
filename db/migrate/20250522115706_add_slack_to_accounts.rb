class AddSlackToAccounts < ActiveRecord::Migration[7.2]
  disable_ddl_transaction!
  verbose!

  def change
    add_column :accounts, :slack_invited_at,  :datetime
    add_column :accounts, :slack_accepted_at, :datetime
    add_column :accounts, :slack_team_id,     :string
    add_column :accounts, :slack_channel_id,  :string

    add_index :accounts, :slack_channel_id, unique: true, algorithm: :concurrently
    add_index :accounts, :slack_team_id,    unique: true, algorithm: :concurrently
  end
end
