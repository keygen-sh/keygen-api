class AddProtectedToPolicies < ActiveRecord::Migration[5.0]
  def change
    add_column :policies, :protected, :boolean, default: false
  end
end
