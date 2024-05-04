class AddMaxUsersToPolicies < ActiveRecord::Migration[7.1]
  def change
    add_column :policies, :max_users, :integer, null: true
  end
end
