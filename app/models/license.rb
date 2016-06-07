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
    (expiry.nil? || expiry > DateTime.now) &&
      (!activations.nil? && activations > 0)
  end
end
