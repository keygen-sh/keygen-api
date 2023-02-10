class AddEnvironmentToGroupOwners < ActiveRecord::Migration[7.0]
  def change
    add_column :group_owners, :environment_id, :uuid, null: true

    add_index :group_owners, :environment_id
  end
end
