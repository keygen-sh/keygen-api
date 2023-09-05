class AddMachineMatchingStrategyToPolicies < ActiveRecord::Migration[7.0]
  def change
    add_column :policies, :machine_matching_strategy, :string, null: true
  end
end
