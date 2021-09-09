class AddMaxUsesOverrideToLicenses < ActiveRecord::Migration[6.1]
  def change
    add_column :licenses, :max_uses_override, :integer
  end
end
