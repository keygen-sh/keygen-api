class SerializableMachine < SerializableBase
  type 'machines'

  attribute :fingerprint
  attribute :ip
  attribute :hostname
  attribute :platform
  attribute :created_at
  attribute :updated_at
  attribute :name
  attribute :metadata

  has_one :product
  has_one :user
  has_one :account
  has_one :license
end
