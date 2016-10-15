class UserSerializer < BaseSerializer
  type :users

  attributes [
    :id,
    :name,
    :email,
    :meta,
    :created,
    :updated
  ]

  belongs_to :account
  has_many :licenses
  has_many :products, through: :licenses
  has_many :machines, through: :licenses
  has_one :token
end
