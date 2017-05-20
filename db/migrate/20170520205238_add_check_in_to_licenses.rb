class AddCheckInToLicenses < ActiveRecord::Migration[5.0]
  def change
    add_column :licenses, :last_check_in_at, :datetime
  end
end
