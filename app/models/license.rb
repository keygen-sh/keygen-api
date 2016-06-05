class License < ApplicationRecord
  belongs_to :account
  belongs_to :user
  belongs_to :product
  belongs_to :policy
  serialize :active_machines, Array

  validates :key,
    presence: true,
    uniqueness: { scope: [:account_id, :product_id] }
end
