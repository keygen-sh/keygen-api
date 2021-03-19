class AddMachinesCoreCountToLicenses < ActiveRecord::Migration[5.2]
  def change
    add_column :licenses, :machines_core_count, :integer
  end
end
