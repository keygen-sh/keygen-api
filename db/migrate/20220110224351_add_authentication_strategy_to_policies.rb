class AddAuthenticationStrategyToPolicies < ActiveRecord::Migration[6.1]
  def change
    add_column :policies, :authentication_strategy, :string, null: true
  end
end
