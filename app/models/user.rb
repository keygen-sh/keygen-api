class User < ApplicationRecord
  has_secure_password
  belongs_to :account
  has_one :license

  has_secure_password

  # before_create -> { self.auth_token = Token.new }
  before_save -> { self.email = email.downcase }

  validates :name, presence: true
  validates :email,
    presence: true,
    length: { maximum: 255 },
    format: { with: /\A[\w+\-.]+@[a-z\d\-.]+\.[a-z]+\z/i },
    uniqueness: { case_sensitive: false }
end
