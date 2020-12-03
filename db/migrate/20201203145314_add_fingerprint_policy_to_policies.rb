class AddFingerprintPolicyToPolicies < ActiveRecord::Migration[5.2]
  def change
    add_column :policies, :fingerprint_policy, :string, null: true
  end
end
