class AddDefaultValueToRole < ActiveRecord::Migration[5.0]
  def change
    change_column :users, :role, :string, default: "user"
  end
end
