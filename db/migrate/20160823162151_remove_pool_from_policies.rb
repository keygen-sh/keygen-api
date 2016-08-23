class RemovePoolFromPolicies < ActiveRecord::Migration[5.0]
  def change
    remove_column :policies, :pool, :string
  end
end
