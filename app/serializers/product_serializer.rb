class ProductSerializer < BaseSerializer
  attributes :id, :name, :platforms

  belongs_to :account
  has_many :users
  has_many :policies, dependent: :destroy
  has_many :licenses, through: :policies

  def id
    object.hashid
  end
end
