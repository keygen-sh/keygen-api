class Product < ApplicationRecord
  belongs_to :account
  has_many :users
  has_many :policies
  has_many :licenses, through: :policies
  serialize :platforms, Array
end
