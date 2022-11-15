class AddLastCheckOutAtToMachines < ActiveRecord::Migration[7.0]
  def change
    add_column :machines, :last_check_out_at, :timestamp, null: true
  end
end
