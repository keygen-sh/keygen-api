class Product < ApplicationRecord
  belongs_to :account
  has_and_belongs_to_many :users
  has_many :policies, dependent: :destroy
  has_many :licenses, through: :policies

  serialize :platforms, Array

  validates :account, presence: { message: "must exist" }
end
