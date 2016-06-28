class AccountSerializer < BaseSerializer
  attributes :id, :name, :subdomain, :status, :created, :updated

  belongs_to :plan
  has_many :users
  has_many :products
  has_many :policies, through: :products
  has_many :licenses, through: :policies
  # has_one :billing, as: :customer

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
