class Policy < ApplicationRecord
  belongs_to :account
  has_many :licenses
  serialize :pool
end
