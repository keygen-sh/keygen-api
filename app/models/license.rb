class License < ApplicationRecord
  belongs_to :account
  belongs_to :user
  belongs_to :policy

  serialize :active_machines, Array

  validates :account, presence: { message: "must exist" }
  validates :user, presence: { message: "must exist" }
  validates :policy, presence: { message: "must exist" }
  validates :key,
    presence: true,
    uniqueness: { scope: :policy_id }

  def license_valid?
    # Check if license is expired
    return false unless expiry.nil? || expiry > DateTime.now
    # Check if license allows floating and if not, should have single activation
    return true if policy.floating && active_machines.length == 1
    # Assume floating, should have at least 1 activation but no more than policy allows
    return true if active_machines.length >= 1 && active_machines.length <= policy.max_activations
    # Otherwise, assume invalid
    return false
  end
end
