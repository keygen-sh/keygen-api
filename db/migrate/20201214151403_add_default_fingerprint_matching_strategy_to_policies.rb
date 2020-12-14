class AddDefaultFingerprintMatchingStrategyToPolicies < ActiveRecord::Migration[5.2]
  def up
    Policy.update_all fingerprint_matching_strategy: 'MATCH_ANY'
  end

  def down
    Policy.update_all fingerprint_matching_strategy: nil
  end
end
