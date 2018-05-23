class Metric < ApplicationRecord
  include DateRangeable
  include Limitable
  include Pageable

  belongs_to :account

  validates :account, presence: { message: "must exist" }
  validates :metric, presence: true
  validates :data, presence: true

  scope :metrics, -> (*metrics) { where metric: metrics }
end
