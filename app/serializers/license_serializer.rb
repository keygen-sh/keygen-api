class LicenseSerializer < BaseSerializer
  attributes :id, :key, :expiry, :active_machines

  belongs_to :user
  belongs_to :policy

  def id
    object.hashid
  end
end
