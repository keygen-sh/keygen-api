class Billing < ApplicationRecord
  belongs_to :customer, polymorphic: true
end
