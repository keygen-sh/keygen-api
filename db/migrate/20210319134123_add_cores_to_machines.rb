class AddCoresToMachines < ActiveRecord::Migration[5.2]
  def change
    add_column :machines, :cores, :integer
  end
end
