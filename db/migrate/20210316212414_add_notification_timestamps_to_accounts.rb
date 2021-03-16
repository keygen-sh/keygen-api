class AddNotificationTimestampsToAccounts < ActiveRecord::Migration[5.2]
  def change
    add_column :accounts, :last_low_activity_lifeline_sent_at, :datetime
    add_column :accounts, :last_trial_will_end_sent_at, :datetime
  end
end
