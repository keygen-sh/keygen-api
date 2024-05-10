class AddProcessLeasingStrategyToPolicies < ActiveRecord::Migration[7.1]
  def change
    add_column :policies, :process_leasing_strategy, :string, null: true
  end
end
