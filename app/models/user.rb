class User < ApplicationRecord
  include Tokenable

  has_secure_password
  belongs_to :account
  has_one :license

  before_save -> { self.email = email.downcase }

  validates :name, presence: true
  validates :email,
    presence: true,
    length: { maximum: 255 },
    format: { with: /\A[\w+\-.]+@[a-z\d\-.]+\.[a-z]+\z/i },
    uniqueness: { case_sensitive: false }
end
