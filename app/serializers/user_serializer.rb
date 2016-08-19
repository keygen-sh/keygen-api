class UserSerializer < BaseSerializer
  type "users"

  attributes [
    :id,
    :name,
    :email,
    :role,
    :meta,
    :created,
    :updated
  ]

  belongs_to :account
  has_many :products
  has_many :licenses
  # has_one :billing
end
