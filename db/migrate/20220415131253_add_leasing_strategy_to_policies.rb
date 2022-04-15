class AddLeasingStrategyToPolicies < ActiveRecord::Migration[7.0]
  def change
    add_column :policies, :leasing_strategy, :string, null: true
  end
end
