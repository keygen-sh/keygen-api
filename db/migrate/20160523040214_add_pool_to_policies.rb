class AddPoolToPolicies < ActiveRecord::Migration[5.0]
  def change
    add_column :policies, :pool, :string
  end
end
