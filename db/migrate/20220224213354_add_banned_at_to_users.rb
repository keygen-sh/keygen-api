class AddBannedAtToUsers < ActiveRecord::Migration[6.1]
  def change
    add_column :users, :banned_at, :timestamp, null: true
  end
end
