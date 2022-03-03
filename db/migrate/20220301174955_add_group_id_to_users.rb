class AddGroupIdToUsers < ActiveRecord::Migration[6.1]
  def change
    add_column :users, :group_id, :uuid, null: true
  end
end
