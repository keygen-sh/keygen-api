class AddMaxUsersOverrideToLicenses < ActiveRecord::Migration[7.1]
  def change
    add_column :licenses, :max_users_override, :integer, null: true
  end
end
