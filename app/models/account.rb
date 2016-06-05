class Account < ApplicationRecord
  belongs_to :plan
  has_many :licenses
  has_many :policies
  has_many :products
  has_many :users
  has_one :billing, as: :customer

  before_save -> { self.subdomain = subdomain.downcase }

  validates :name, presence: true
  validates :subdomain,
    presence: true,
    exclusion: { in: %w(www api), message: "%{value} is reserved." },
    uniqueness: { case_sensitive: false },
    format: { with: /\A[\w_]+\Z/i },
    length: { maximum: 255 }

  def admins
    self.users.select &:admin?
  end
end
