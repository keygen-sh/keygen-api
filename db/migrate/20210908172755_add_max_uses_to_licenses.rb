class AddMaxUsesToLicenses < ActiveRecord::Migration[6.1]
  def change
    add_column :licenses, :max_uses, :integer
  end
end
