class AddStdoutToUsers < ActiveRecord::Migration[6.1]
  def change
    add_column :users, :stdout_unsubscribed_at, :datetime
    add_column :users, :stdout_last_sent_at, :datetime
  end
end
