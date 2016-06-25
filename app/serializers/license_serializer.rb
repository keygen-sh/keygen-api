class LicenseSerializer < BaseSerializer
  attributes :id, :key, :expiry, :active_machines, :created, :updated

  belongs_to :user
  belongs_to :policy

  def id
    object.hashid
  end

  def created
    object.created_at
  end

  def updated
    object.updated_at
  end
end
