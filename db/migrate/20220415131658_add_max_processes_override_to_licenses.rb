class AddMaxProcessesOverrideToLicenses < ActiveRecord::Migration[7.0]
  def change
    add_column :licenses, :max_processes_override, :integer, null: true
  end
end
