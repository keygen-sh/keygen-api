class RequestLog < ApplicationRecord
  include DateRangeable
  include Limitable
  include Pageable

  belongs_to :account

  validates :account, presence: { message: "must exist" }

  scope :current_period, -> {
    date_start = 2.weeks.ago.beginning_of_day
    date_end = Time.current.end_of_day

    where created_at: (date_start..date_end)
  }
end
