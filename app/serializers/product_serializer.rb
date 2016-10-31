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
  has_many :machines, through: :licenses
  has_many :users, through: :licenses
  has_one :token
end

# == Schema Information
#
# Table name: products
#
#  id         :integer          not null, primary key
#  name       :string
#  platforms  :string
#  account_id :integer
#  created_at :datetime         not null
#  updated_at :datetime         not null
#
# Indexes
#
#  index_products_on_account_id  (account_id)
#
