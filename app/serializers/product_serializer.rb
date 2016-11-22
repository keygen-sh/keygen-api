class ProductSerializer < BaseSerializer
  type :products

  attributes [
    :id,
    :name,
    :platforms,
    :metadata,
    :created,
    :updated
  ]

  belongs_to :account
  has_many :policies, dependent: :destroy
  has_many :licenses, through: :policies
  has_many :machines, through: :licenses
  has_many :users, through: :licenses
  has_many :tokens
end

# == Schema Information
#
# Table name: products
#
#  id         :integer          not null, primary key
#  name       :string
#  account_id :integer
#  created_at :datetime         not null
#  updated_at :datetime         not null
#  deleted_at :datetime
#  platforms  :json
#  metadata   :json
#
# Indexes
#
#  index_products_on_account_id  (account_id)
#  index_products_on_deleted_at  (deleted_at)
#
