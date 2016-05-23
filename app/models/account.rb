class Account < ApplicationRecord
  has_many :policies
  has_many :users
end
