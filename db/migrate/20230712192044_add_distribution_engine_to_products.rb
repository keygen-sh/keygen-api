class AddDistributionEngineToProducts < ActiveRecord::Migration[7.0]
  def change
    add_column :products, :distribution_engine, :string, null: true

    add_index :products, :distribution_engine
  end
end
