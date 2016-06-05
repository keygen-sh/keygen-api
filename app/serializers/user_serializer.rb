class UserSerializer < BaseSerializer
  attributes :id, :name, :email

  belongs_to :account
  has_many :licenses
  # has_one :billing

  def id
    object.hashid
  end
end
