class AddComponentUniquenessStrategyToPolicies < ActiveRecord::Migration[7.0]
  def change
    add_column :policies, :component_uniqueness_strategy, :string, null: true
  end
end
