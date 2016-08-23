class AddUserIdToMachines < ActiveRecord::Migration[5.0]
  def change
    add_column :machines, :user_id, :integer
  end
end
