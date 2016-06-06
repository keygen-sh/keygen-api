class AccountSerializer < BaseSerializer
  attributes :id, :name, :subdomain

  belongs_to :plan
  has_many :users
  has_many :products
  has_many :policies, through: :products
  has_many :licenses, through: :policies
  has_one :billing, as: :customer

  def id
    object.hashid
  end
end
