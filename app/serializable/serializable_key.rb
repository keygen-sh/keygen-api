class SerializableKey < SerializableBase
  type 'keys'

  attribute :key
  attribute :created_at
  attribute :updated_at

  has_one :product
  has_one :account
  has_one :policy
end
