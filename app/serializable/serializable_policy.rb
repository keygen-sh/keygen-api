class SerializablePolicy < SerializableBase
  type 'policies'

  attribute :name
  attribute :price
  attribute :duration
  attribute :strict
  attribute :recurring
  attribute :floating
  attribute :use_pool
  attribute :created_at
  attribute :updated_at
  attribute :lock_version
  attribute :max_machines
  attribute :encrypted
  attribute :protected
  attribute :deleted_at
  attribute :metadata

  has_one :account
  has_one :product
  has_many :licenses
  has_many :pool
end
