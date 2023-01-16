class AddIsolationStrategyToEnvironments < ActiveRecord::Migration[7.0]
  def change
    add_column :environments, :isolation_strategy, :string, null: false
  end
end
