class UserSerializer < BaseSerializer
  attributes :id, :name, :email, :meta

  belongs_to :account
  has_many :products
  has_many :licenses
  # has_one :billing

  def id
    object.hashid
  end
end
