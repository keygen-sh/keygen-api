class AddDefaultFingerprintStrategyToPolicies < ActiveRecord::Migration[5.2]
  def up
    Policy.update_all fingerprint_strategy: 'UNIQUE_PER_LICENSE'
  end

  def down
    Policy.update_all fingerprint_strategy: nil
  end
end
