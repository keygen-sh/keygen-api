class Product < ApplicationRecord
  belongs_to :account
  has_and_belongs_to_many :users
  has_many :policies, dependent: :destroy
  has_many :licenses, through: :policies

  accepts_nested_attributes_for :licenses

  serialize :platforms, Array

  validates :account, presence: true
end
