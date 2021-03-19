class AddMaxCoresToPolicies < ActiveRecord::Migration[5.2]
  def change
    add_column :policies, :max_cores, :integer
  end
end
