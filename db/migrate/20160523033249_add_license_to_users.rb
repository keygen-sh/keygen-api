class AddLicenseToUsers < ActiveRecord::Migration[5.0]
  def change
    add_column :users, :license_id, :integer
  end
end
