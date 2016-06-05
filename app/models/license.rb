class License < ApplicationRecord
  belongs_to :account
  belongs_to :user
  belongs_to :product
  belongs_to :policy
  serialize :active_machines, Array
end
