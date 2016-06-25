class ProductSerializer < BaseSerializer
  attributes :id, :name, :platforms, :created, :updated

  belongs_to :account
  has_many :users
  has_many :policies, dependent: :destroy
  has_many :licenses, through: :policies

  def id
    object.hashid
  end

  def created
    object.created_at
  end

  def updated
    object.updated_at
  end
end
