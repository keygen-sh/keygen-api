class AddTransferStrategyToPolicies < ActiveRecord::Migration[6.1]
  def change
    add_column :policies, :transfer_strategy, :string, null: true
  end
end
