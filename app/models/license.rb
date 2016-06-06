class License < ApplicationRecord
  belongs_to :user
  belongs_to :policy

  serialize :active_machines, Array

  validates :user, presence: true
  validates :policy, presence: true
  validates :key,
    presence: true,
    uniqueness: { scope: :policy_id }
end
