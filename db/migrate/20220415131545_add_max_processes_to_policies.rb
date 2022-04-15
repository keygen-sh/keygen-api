class AddMaxProcessesToPolicies < ActiveRecord::Migration[7.0]
  def change
    add_column :policies, :max_processes, :integer, null: true
  end
end
