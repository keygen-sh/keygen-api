class UserSerializer < BaseSerializer
  attributes :id, :name, :email
  belongs_to :account
  has_one :license
end
