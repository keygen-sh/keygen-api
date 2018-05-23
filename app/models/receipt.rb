class Receipt < ApplicationRecord
  belongs_to :billing

  scope :unpaid, -> { where paid: false }
  scope :paid, -> { where paid: true }
end
