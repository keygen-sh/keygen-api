class SerializableToken < SerializableBase
  type 'tokens'

  attribute :digest
  attribute :expiry
  attribute :created_at
  attribute :updated_at

  has_one :account
  has_one :bearer
end
