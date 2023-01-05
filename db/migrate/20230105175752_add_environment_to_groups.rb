class AddEnvironmentToGroups < ActiveRecord::Migration[7.0]
  def change
    add_column :groups, :environment_id, :uuid, null: true

    add_index :groups, :environment_id
  end
end
