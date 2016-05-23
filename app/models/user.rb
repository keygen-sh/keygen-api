class User < ApplicationRecord
  has_secure_password
  belongs_to :account
  has_one :license
end
