class AddMaxMachinesToLicenses < ActiveRecord::Migration[6.1]
  def change
    add_column :licenses, :max_machines, :integer
  end
end
