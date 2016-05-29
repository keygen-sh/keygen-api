class AccountSerializer < BaseSerializer
  attributes :id, :name, :email, :subdomain
  belongs_to :plan
  has_many :policies
  has_many :users
end
