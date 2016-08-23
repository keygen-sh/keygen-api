class LicenseSerializer < BaseSerializer
  type :licenses

  attributes [
    :id,
    :key,
    :expiry,
    :created,
    :updated
  ]

  belongs_to :user
  belongs_to :policy
  has_many :machines
end
