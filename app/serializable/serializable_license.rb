class SerializableLicense < SerializableBase
  type :licenses

  attribute :key
  attribute :expiry
  attribute :created_at
  attribute :updated_at
  attribute :metadata

  has_one :product
  has_one :account
  has_one :user
  has_one :policy
  has_many :machines
end
