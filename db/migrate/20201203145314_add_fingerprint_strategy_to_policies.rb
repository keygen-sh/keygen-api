class AddFingerprintStrategyToPolicies < ActiveRecord::Migration[5.2]
  def change
    add_column :policies, :fingerprint_strategy, :string, null: true
  end
end
