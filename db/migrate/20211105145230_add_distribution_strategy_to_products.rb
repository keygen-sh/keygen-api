class AddDistributionStrategyToProducts < ActiveRecord::Migration[6.1]
  def change
    add_column :products, :distribution_strategy, :string, null: true

    add_index :products, :distribution_strategy
  end
end
