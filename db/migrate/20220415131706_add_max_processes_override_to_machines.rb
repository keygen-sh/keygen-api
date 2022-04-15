class AddMaxProcessesOverrideToMachines < ActiveRecord::Migration[7.0]
  def change
    add_column :machines, :max_processes_override, :integer, null: true
  end
end
