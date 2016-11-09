class AddMetaToMachines < ActiveRecord::Migration[5.0]
  def change
    add_column :machines, :meta, :string
  end
end
