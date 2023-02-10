class AddEnvironmentToKeys < ActiveRecord::Migration[7.0]
  def change
    add_column :keys, :environment_id, :uuid, null: true

    add_index :keys, :environment_id
  end
end
