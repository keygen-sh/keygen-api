class AddMaxCoresOverrideToLicenses < ActiveRecord::Migration[6.1]
  def change
    add_column :licenses, :max_cores_override, :integer
  end
end
