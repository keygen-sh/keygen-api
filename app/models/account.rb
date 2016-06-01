class Account < ApplicationRecord
  belongs_to :plan
  has_many :policies
  has_many :users
  has_one :billing, as: :customer

  validates :name, presence: true

  def admins
    self.users.select &:admin?
  end
end
