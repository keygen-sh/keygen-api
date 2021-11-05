class AddDistributionStrategyToProducts < ActiveRecord::Migration[6.1]
  def change
    add_column :products, :distribution_strategy, :string, null: true
  end
end
