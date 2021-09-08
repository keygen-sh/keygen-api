class AddMaxCoresToLicenses < ActiveRecord::Migration[6.1]
  def change
    add_column :licenses, :max_cores, :integer
  end
end
