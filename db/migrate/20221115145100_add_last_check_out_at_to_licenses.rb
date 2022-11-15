class AddLastCheckOutAtToLicenses < ActiveRecord::Migration[7.0]
  def change
    add_column :licenses, :last_check_out_at, :timestamp, null: true
  end
end
