class AddDefaultFingerprintPoliciesForPolicies < ActiveRecord::Migration[5.2]
  def up
    Policy.update_all fingerprint_policy: 'UNIQUE_PER_LICENSE'
  end

  def down
    Policy.update_all fingerprint_policy: nil
  end
end
