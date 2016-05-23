class License < ApplicationRecord
  belongs_to :user
  belongs_to :policy
  serialize :active_machines
end
