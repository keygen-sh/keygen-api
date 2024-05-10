class AddMachineLeasingStrategyToPolicies < ActiveRecord::Migration[7.1]
  def change
    add_column :policies, :machine_leasing_strategy, :string, null: true
  end
end
