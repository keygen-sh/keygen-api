class AddExpirationStrategyToPolicies < ActiveRecord::Migration[6.1]
  def change
    add_column :policies, :expiration_strategy, :string, null: true
  end
end
