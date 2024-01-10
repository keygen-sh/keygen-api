# frozen_string_literal: true

class Metric < ApplicationRecord
  include DateRangeable
  include Accountable
  include Limitable
  include Orderable
  include Pageable

  belongs_to :event_type

  has_account

  # NOTE(ezekg) Would love to add a default instead of this, but alas,
  #             the table is too big and it would break everything.
  before_create -> { self.created_date ||= (created_at || Date.current) }

  validates :data, presence: true

  scope :with_events, -> (*events) { where(event_type_id: EventType.where(event: events).pluck(:id)) }
  scope :for_current_period, -> {
    date_start = 2.weeks.ago.beginning_of_day
    date_end = Time.current

    where created_at: (date_start..date_end)
  }
end
