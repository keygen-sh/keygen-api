class UserSerializer < BaseSerializer
  attributes :id, :name, :email, :role, :meta, :created, :updated

  belongs_to :account
  has_many :products
  has_many :licenses
  # has_one :billing

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
