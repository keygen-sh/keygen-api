class SerializableUser < SerializableBase
  type 'users'

  attribute :name
  attribute :email
  attribute :metadata
  attribute :created_at
  attribute :updated_at

  has_one :account
  has_many :licenses
  has_many :products
  has_many :machines
  has_many :tokens
end
