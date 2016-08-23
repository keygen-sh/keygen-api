class AddNameToMachines < ActiveRecord::Migration[5.0]
  def change
    add_column :machines, :name, :string
  end
end
