class Account < ApplicationRecord
  belongs_to :plan
  has_many :users, dependent: :destroy
  has_many :products, dependent: :destroy
  has_many :policies, through: :products
  has_many :licenses, through: :policies
  has_one :billing, as: :customer, dependent: :destroy

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
