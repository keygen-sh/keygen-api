class AccountSerializer < BaseSerializer
  type :accounts

  attributes [
    :id,
    :name,
    :subdomain,
    :status,
    :activated,
    :created,
    :updated
  ]

  belongs_to :plan
  has_many :users
  has_many :products
  has_many :policies, through: :products
  has_many :licenses, through: :policies
  has_one :billing, as: :customer
end
