class AddIndexToUserEmail < ActiveRecord::Migration[5.0]
  def change
    add_index :users, :email
  end
end
