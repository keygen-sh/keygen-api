class ProductSerializer < BaseSerializer
  type :products

  attributes [
    :id,
    :name,
    :platforms,
    :created,
    :updated
  ]

  belongs_to :account
  has_many :policies, dependent: :destroy
  has_many :licenses, through: :policies
  has_many :users, through: :licenses
  has_one :token
end
