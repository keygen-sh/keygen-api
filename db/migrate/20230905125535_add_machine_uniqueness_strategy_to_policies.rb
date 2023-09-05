class AddMachineUniquenessStrategyToPolicies < ActiveRecord::Migration[7.0]
  def change
    add_column :policies, :machine_uniqueness_strategy, :string, null: true
  end
end
