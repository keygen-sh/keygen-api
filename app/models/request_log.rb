class RequestLog < ApplicationRecord
  include DateRangeable
  include Limitable
  include Pageable

  belongs_to :account

  validates :account, presence: { message: "must exist" }
end
