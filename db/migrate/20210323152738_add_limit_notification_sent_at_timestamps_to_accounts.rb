class AddLimitNotificationSentAtTimestampsToAccounts < ActiveRecord::Migration[5.2]
  def change
    add_column :accounts, :last_license_limit_exceeded_sent_at, :datetime
    add_column :accounts, :last_request_limit_exceeded_sent_at, :datetime
  end
end
