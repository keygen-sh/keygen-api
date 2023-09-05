class AddComponentMatchingStrategyToPolicies < ActiveRecord::Migration[7.0]
  def change
    add_column :policies, :component_matching_strategy, :string, null: true
  end
end
