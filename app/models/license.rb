class License < ApplicationRecord
  belongs_to :account
  belongs_to :user
  belongs_to :policy

  serialize :active_machines, Array

  before_validation :generate_license_key

  # validates_associated :account, message: -> (_, obj) { obj[:value].errors.full_messages.first }
  # validates_associated :policy, message: -> (_, obj) { obj[:value].errors.full_messages.first }
  validates :account, presence: { message: "must exist" }
  validates :user, presence: { message: "must exist" }
  validates :policy, presence: { message: "must exist" }, uniqueness: { scope: :user_id, message: "user already has a license with this policy" }

  validate do
    errors.add :active_machines, "count has reached maximum allowed by policy" if active_machines.size > policy.max_activations
  end

  validates :key, presence: true, blank: false, uniqueness: { scope: :policy_id }

  def license_valid?
    # Check if license is expired
    return false unless expiry.nil? || expiry > DateTime.now
    # Check if license allows floating and if not, should have single activation
    return true if !policy.floating && active_machines.length == 1
    # Assume floating, should have at least 1 activation but no more than policy allows
    return true if policy.floating && active_machines.length >= 1 && active_machines.length <= policy.max_activations
    # Otherwise, assume invalid
    return false
  end

  private

  def generate_license_key
    if policy.pool?
      license_key = policy.pop

      if license_key
        self.key = license_key
      else
        errors.add :policy, "license pool is empty"
      end
    else
      self.key = generate_token_for :license, :key
    end
  end
end
