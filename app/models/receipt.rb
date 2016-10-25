class Receipt < ApplicationRecord
  belongs_to :billing

  scope :unpaid, -> { where(unpaid: true) }
  scope :paid, -> { where(paid: true) }
end
