class AddMaxMachinesOverrideToLicenses < ActiveRecord::Migration[6.1]
  def change
    add_column :licenses, :max_machines_override, :integer
  end
end
