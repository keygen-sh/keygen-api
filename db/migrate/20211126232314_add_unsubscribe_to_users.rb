class AddUnsubscribeToUsers < ActiveRecord::Migration[6.1]
  def change
    add_column :users, :unsubscribed_from_stdout_at, :datetime
  end
end
