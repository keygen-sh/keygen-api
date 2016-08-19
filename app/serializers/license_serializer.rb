class LicenseSerializer < BaseSerializer
  type "licenses"

  attributes [
    :id,
    :key,
    :expiry,
    :active_machines,
    :created,
    :updated
  ]

  belongs_to :user
  belongs_to :policy
end
