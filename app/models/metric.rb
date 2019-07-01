class Metric < ApplicationRecord
  include DateRangeable
  include Searchable
  include Limitable
  include Pageable

  SEARCH_ATTRIBUTES = %i[id metric data].freeze
  SEARCH_RELATIONSHIPS = {}.freeze

  search attributes: SEARCH_ATTRIBUTES, relationships: SEARCH_RELATIONSHIPS

  belongs_to :account

  validates :account, presence: { message: "must exist" }
  validates :metric, presence: true
  validates :data, presence: true

  scope :metrics, -> (*metrics) { where metric: metrics }
  scope :current_period, -> {
    date_start = 2.weeks.ago.beginning_of_day
    date_end = Time.current.end_of_day

    where created_at: (date_start..date_end)
  }
end
