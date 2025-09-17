class AddMemoryAndDiskToMachines < ActiveRecord::Migration[7.0]
  def change
    add_column :machines, :memory, :bigint
    add_column :machines, :disk, :bigint
  end
end
