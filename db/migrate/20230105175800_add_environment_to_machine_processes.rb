class AddEnvironmentToMachineProcesses < ActiveRecord::Migration[7.0]
  def change
    add_column :machine_processes, :environment_id, :uuid, null: true

    add_index :machine_processes, :environment_id
  end
end
