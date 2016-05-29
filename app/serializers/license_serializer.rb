class LicenseSerializer < BaseSerializer
  attributes :id, :key, :expiry, :activations, :active_machines
  belongs_to :user
  belongs_to :policy
end
