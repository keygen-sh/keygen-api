# frozen_string_literal: true

class RequestLog < ApplicationRecord
  include DateRangeable
  include Limitable
  include Pageable
  include Searchable

  SEARCH_ATTRIBUTES = [{ fuzzy: [:request_id, :status, :method, :url, :ip] }].freeze
  SEARCH_RELATIONSHIPS = {}.freeze

  search attributes: SEARCH_ATTRIBUTES, relationships: SEARCH_RELATIONSHIPS

  belongs_to :account

  validates :account, presence: { message: "must exist" }

  scope :current_period, -> {
    date_start = 2.weeks.ago.beginning_of_day
    date_end = Time.current.end_of_day

    where created_at: (date_start..date_end)
  }
end
