class User < ApplicationRecord
  include PasswordReset
  include AuthToken

  has_secure_password

  belongs_to :account
  has_and_belongs_to_many :products
  has_many :licenses, dependent: :destroy
  # has_one :billing, as: :customer

  before_save -> { self.email = email.downcase }

  validates :account, presence: true
  validates :name, presence: true
  validates :email,
    presence: true,
    length: { maximum: 255 },
    format: { with: /\A[\w+\-.]+@[a-z\d\-.]+\.[a-z]+\z/i },
    uniqueness: { case_sensitive: false, scope: :account_id }

  def architect?
    self.role == "architect"
  end

  def admin?
    self.role == "admin"
  end

  def user?
    self.role == "user"
  end

  def atleast?(role)
    roles = [
      "architect",
      "admin",
      "user"
    ]

    a = roles.index self.role.to_s
    b = roles.index role.to_s

    return false if a.nil? || b.nil?

    a <= b
  end
end
