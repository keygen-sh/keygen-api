class AddEnvironmentToUsers < ActiveRecord::Migration[7.0]
  def change
    add_column :users, :environment_id, :uuid, null: true

    add_index :users, :environment_id
  end
end
