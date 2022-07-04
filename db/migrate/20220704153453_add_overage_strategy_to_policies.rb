class AddOverageStrategyToPolicies < ActiveRecord::Migration[7.0]
  def change
    add_column :policies, :overage_strategy, :string, null: true
  end
end
