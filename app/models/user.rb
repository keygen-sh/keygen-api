class User < ApplicationRecord
  include PasswordReset
  include AuthToken

  has_secure_password

  belongs_to :account
  has_and_belongs_to_many :products
  has_many :licenses, dependent: :destroy
  # has_one :billing, as: :customer

  before_save -> { self.email = email.downcase }

  validates :account, presence: { message: "must exist" }
  validates :name, presence: true
  validates :email,
    presence: true,
    length: { maximum: 255 },
    format: { with: /\A[\w+\-.]+@[a-z\d\-.]+\.[a-z]+\z/i },
    uniqueness: { case_sensitive: false, scope: :account_id }

  def admin?
    self.role == "admin"
  end
end
