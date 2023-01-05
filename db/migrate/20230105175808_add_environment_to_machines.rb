class AddEnvironmentToMachines < ActiveRecord::Migration[7.0]
  def change
    add_column :machines, :environment_id, :uuid, null: true

    add_index :machines, :environment_id
  end
end
