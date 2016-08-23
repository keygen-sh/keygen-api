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
  has_many :users
  has_many :policies, dependent: :destroy
  has_many :licenses, through: :policies
end
