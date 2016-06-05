class AccountSerializer < BaseSerializer
  attributes :id, :name, :subdomain

  belongs_to :plan
  has_many :products
  has_many :policies
  has_many :users
  has_one :billing

  def id
    object.hashid
  end
end
