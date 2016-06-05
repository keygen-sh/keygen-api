class ProductSerializer < BaseSerializer
  attributes :id, :name, :platforms

  belongs_to :account
  has_many :users
  has_many :policies
  has_many :licenses

  def id
    object.hashid
  end
end
