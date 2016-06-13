class Product < ApplicationRecord
  belongs_to :account
  has_and_belongs_to_many :users
  has_many :policies, dependent: :destroy
  has_many :licenses, through: :policies

  serialize :platforms, Array

  validates_associated :account, message: -> (_, obj) { obj[:value].errors.full_messages.first }
  validates :account, presence: { message: "must exist" }

  scope :page, -> (page = {}) {
    paginate(page[:number]).per page[:size]
  }
end
