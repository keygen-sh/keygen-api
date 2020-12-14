class AddFingerprintMatchingStrategyToPolicies < ActiveRecord::Migration[5.2]
  def change
    add_column :policies, :fingerprint_matching_strategy, :string, null: true
  end
end
