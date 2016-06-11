class Account < ApplicationRecord
  include ReservedSubdomains

  belongs_to :plan
  has_many :users, dependent: :destroy
  has_many :products, dependent: :destroy
  has_many :policies, dependent: :destroy
  has_many :licenses, dependent: :destroy
  has_one :billing, as: :customer, dependent: :destroy

  before_save -> { self.subdomain = subdomain.downcase }

  validates :name, presence: true
  validates :subdomain,
    presence: true,
    exclusion: { in: RESERVED_SUBDOMAINS, message: "%{value} is reserved." },
    uniqueness: { case_sensitive: false },
    format: { with: /\A[\w_]+\Z/i },
    length: { maximum: 255 }

  def admins
    self.users.select &:admin?
  end
end
