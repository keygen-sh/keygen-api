class SerializableAccount < SerializableBase
  type 'accounts'

  attribute :company
  attribute :name
  attribute :created_at
  attribute :updated_at

  has_one :billing
  has_one :plan
  has_many :webhook_endpoints
  has_many :webhook_events
  has_many :tokens
  has_many :users
  has_many :products
  has_many :policies
  has_many :keys
  has_many :licenses
  has_many :machines
end
